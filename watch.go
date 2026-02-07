package main

import (
	"os"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

const (
	proxyExeName  = "proxy.exe"
	checkInterval = 2 * time.Second
)

type PROCESSENTRY32 struct {
	Size              uint32
	CntUsage          uint32
	ProcessID         uint32
	DefaultHeapID     uintptr
	ModuleID          uint32
	CntThreads        uint32
	ParentProcessID   uint32
	PcPriClassBase    int32
	Flags             uint32
	ExeFile           [260]uint16
}

var (
	modKernel32                  = syscall.NewLazyDLL("kernel32.dll")
	procCreateToolhelp32Snapshot = modKernel32.NewProc("CreateToolhelp32Snapshot")
	procProcess32FirstW          = modKernel32.NewProc("Process32FirstW")
	procProcess32NextW           = modKernel32.NewProc("Process32NextW")

	modAdvapi32        = syscall.NewLazyDLL("advapi32.dll")
	procRegOpenKeyExW  = modAdvapi32.NewProc("RegOpenKeyExW")
	procRegSetValueExW = modAdvapi32.NewProc("RegSetValueExW")
	procRegCloseKey    = modAdvapi32.NewProc("RegCloseKey")
)

func proxyRunning() bool {
	const TH32CS_SNAPPROCESS = 0x00000002

	snap, _, _ := procCreateToolhelp32Snapshot.Call(
		uintptr(TH32CS_SNAPPROCESS),
		0,
	)
	if snap == uintptr(syscall.InvalidHandle) {
		return false
	}
	defer syscall.CloseHandle(syscall.Handle(snap))

	var entry PROCESSENTRY32
	entry.Size = uint32(unsafe.Sizeof(entry))

	ret, _, _ := procProcess32FirstW.Call(
		snap,
		uintptr(unsafe.Pointer(&entry)),
	)
	if ret == 0 {
		return false
	}

	for {
		name := syscall.UTF16ToString(entry.ExeFile[:])
		if strings.EqualFold(name, proxyExeName) {
			return true
		}

		ret, _, _ = procProcess32NextW.Call(
			snap,
			uintptr(unsafe.Pointer(&entry)),
		)
		if ret == 0 {
			break
		}
	}
	return false
}

func disableSystemProxy() {
	var hKey syscall.Handle

	subKey, _ := syscall.UTF16PtrFromString(
		`Software\Microsoft\Windows\CurrentVersion\Internet Settings`,
	)

	// 打开注册表 key
	ret, _, _ := procRegOpenKeyExW.Call(
		uintptr(syscall.HKEY_CURRENT_USER),
		uintptr(unsafe.Pointer(subKey)),
		0,
		syscall.KEY_SET_VALUE,
		uintptr(unsafe.Pointer(&hKey)),
	)
	if ret != 0 {
		return
	}
	defer procRegCloseKey.Call(uintptr(hKey))

	valueName, _ := syscall.UTF16PtrFromString("ProxyEnable")
	data := uint32(0)

	// 写入 ProxyEnable = 0
	procRegSetValueExW.Call(
		uintptr(hKey),
		uintptr(unsafe.Pointer(valueName)),
		0,
		syscall.REG_DWORD,
		uintptr(unsafe.Pointer(&data)),
		4,
	)
}

func main() {
	// 等待 proxy 首次出现
	for {
		if proxyRunning() {
			break
		}
		time.Sleep(time.Second)
	}

	// 守护
	for {
		time.Sleep(checkInterval)
		if !proxyRunning() {
			disableSystemProxy()
			os.Exit(0)
		}
	}
}
