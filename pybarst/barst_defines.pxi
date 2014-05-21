'''Defines all the structs and types used with Barst.
'''

from libc.stdint cimport int64_t, uint64_t, int32_t, uint32_t, uint16_t,\
int16_t, uint8_t, int8_t, uintptr_t
from libcpp cimport bool


cdef extern from * nogil:
    ctypedef unsigned long DWORD
    ctypedef unsigned long ULONG
    ctypedef int BOOL
    ctypedef void *HANDLE
    ctypedef char *LPSTR
    ctypedef const char *LPCSTR
    ctypedef DWORD *LPDWORD
    ctypedef const void *LPCVOID
    ctypedef void *LPVOID
    ctypedef char *va_list
    ctypedef HANDLE HLOCAL

    struct _SECURITY_ATTRIBUTES:
        pass
    ctypedef _SECURITY_ATTRIBUTES SECURITY_ATTRIBUTES
    ctypedef _SECURITY_ATTRIBUTES *LPSECURITY_ATTRIBUTES
    struct _OVERLAPPED:
        pass
    ctypedef _OVERLAPPED OVERLAPPED
    ctypedef _OVERLAPPED *LPOVERLAPPED
    union _LARGE_INTEGER:
        pass
    ctypedef _LARGE_INTEGER LARGE_INTEGER

    DWORD OPEN_EXISTING
    DWORD ERROR_PIPE_BUSY
    DWORD PIPE_READMODE_MESSAGE
    DWORD PIPE_WAIT
    DWORD GENERIC_READ
    DWORD GENERIC_WRITE
    DWORD FORMAT_MESSAGE_ALLOCATE_BUFFER
    DWORD FORMAT_MESSAGE_FROM_SYSTEM
    DWORD FORMAT_MESSAGE_IGNORE_INSERTS
    HANDLE INVALID_HANDLE_VALUE

    HANDLE __stdcall CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess,
         DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes,
         DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes,
         HANDLE hTemplateFile)
    DWORD __stdcall GetLastError()
    BOOL __stdcall WaitNamedPipeA(LPCSTR lpNamedPipeName, DWORD nTimeOut)
    BOOL __stdcall SetNamedPipeHandleState(HANDLE hNamedPipe, LPDWORD lpMode,
                                           LPDWORD lpMaxCollectionCount,
                                           LPDWORD lpCollectDataTimeout)
    BOOL __stdcall CloseHandle(HANDLE hObject)
    BOOL __stdcall WriteFile(HANDLE hFile, LPCVOID lpBuffer,
        DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten,
        LPOVERLAPPED lpOverlapped)
    BOOL __stdcall ReadFile(HANDLE hFile, LPVOID lpBuffer,
        DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead,
        LPOVERLAPPED lpOverlapped)
    DWORD __stdcall FormatMessageA(DWORD dwFlags, LPCVOID lpSource,
        DWORD dwMessageId, DWORD dwLanguageId, LPSTR lpBuffer, DWORD nSize,
        va_list *Arguments)
    HLOCAL __stdcall LocalFree(HLOCAL hMem)

DEF SERIAL_MAX_LENGTH_CONST = 24


cdef extern from "cpl defs.h":
    int BAD_INPUT_PARAMS
    int NO_SYS_RESOURCE
    int ALREADY_OPEN
    int SIZE_MISSMATCH
    int INVALID_CHANN
    int UNKWN_ERROR
    int DRIVER_ERROR
    int DEVICE_CLOSING
    int INVALID_DEVICE
    int INACTIVE_DEVICE
    int INVALID_COMMAND
    int UNEXPECTED_READ
    int NO_CHAN
    int BUFF_TOO_SMALL
    int NOT_FOUND
    int TIMED_OUT
    int INVALID_MAN
    int RW_FAILED
    int LIBRARY_ERROR

    # input from the point of view of server, for client it's output
    DWORD MIN_BUFF_IN
    DWORD MIN_BUFF_OUT

    int SERIAL_MAX_LENGTH

    enum EQueryType:
        eNone= 0
        eQuery
        eSet
        eDelete
        ePassOn
        eData
        eTrigger
        eResponse
        eVersion
        eActivate
        eInactivate
        eResponseEx
        eResponseExL
        eResponseExD
        eFTDIChan
        eFTDIChanInit
        eFTDIPeriphInit
        eFTDIMultiWriteInit
        eFTDIADCInit
        eFTDIMultiReadInit
        eFTDIPinReadInit
        eFTDIPinWriteInit
        eRTVChanInit,
        eSerialChanInit,
        eFTDIMultiWriteData
        eADCData
        eFTDIMultiReadData
        eFTDIPinWDataArray
        eFTDIPinWDataBufArray
        eFTDIPinRDataArray
        eRTVImageBuf
        eSerialWriteData
        eSerialReadData
        eMCDAQChanInit
        eMCDAQWriteData
        eCancelReadRequest
        eServerTime

        eFTDIMan = 1000
        eRTVMan
        eSerialMan
        eMCDAQMan

    struct SBaseIn:
        DWORD dwSize
        EQueryType eType
        #union:
        int nChan
        EQueryType eType2
        DWORD dwInfo
        int nError
    struct SBase:
        DWORD dwSize
        EQueryType eType
    struct SBaseOut:
        SBaseIn sBaseIn
        #union:
        char *szName
        double dDouble
        LARGE_INTEGER llLargeInteger
        bool bActive

    struct SChanInitFTDI:
        DWORD dwBuffIn
        DWORD dwBuffOut
        DWORD dwBaud
    struct SInitPeriphFT:
        int nChan
        DWORD dwBuff
        DWORD dwMinSizeR
        DWORD dwMinSizeW
        DWORD dwMaxBaud
        unsigned char ucBitMode
        unsigned char ucBitOutput
    struct SValveInit:
        DWORD dwBoards
        DWORD dwClkPerData
        unsigned char ucClk
        unsigned char ucData
        unsigned char ucLatch
        bool bContinuous
    struct SValveData:
        unsigned short usIndex
        bool bValue
    struct SPinInit:
        unsigned short usBytesUsed
        unsigned char ucActivePins
        unsigned char ucInitialVal
        bool bContinuous
    struct SPinWData:
        unsigned short usRepeat
        unsigned char ucValue
        unsigned char ucPinSelect
    struct SADCInit:
        float fUSBBuffToUse
        DWORD dwDataPerTrans
        unsigned char ucClk
        unsigned char ucLowestDataBit
        unsigned char ucDataBits
        unsigned char ucRateFilter
        bool bChop
        bool bChan1
        bool bChan2
        unsigned char ucInputRange
        unsigned char ucBitsPerData
        bool bStatusReg
        bool bReverseBytes
        bool bConfigureADC
    struct SADCData:
        SBaseIn sDataBase
        SBase sBase
        DWORD dwPos
        DWORD dwCount1
        DWORD dwChan2Start
        DWORD dwCount2
        DWORD dwChan1S
        DWORD dwChan2S
        float fSpaceFull
        float fTimeWorked
        float fDataRate
        unsigned char ucError
        double dStartTime
    struct _ft_device_list_info_node_os:
        ULONG Flags
        ULONG Type
        ULONG ID
        DWORD LocId
        char SerialNumber[16]
        char Description[64]
        uint64_t ftHandle
    ctypedef _ft_device_list_info_node_os FT_DEVICE_LIST_INFO_NODE_OS

    struct SChanInitRTV:
        unsigned char ucBrightness
        unsigned char ucHue
        unsigned char ucUSat
        unsigned char ucVSat
        unsigned char ucLumaContrast
        unsigned char ucLumaFilt
        unsigned char ucColorFmt
        unsigned char ucVideoFmt
        bool bLossless
        unsigned char ucBpp
        int nWidth
        int nHeight
        DWORD dwBuffSize

    struct SChanInitSerial:
        char szPortName[SERIAL_MAX_LENGTH_CONST]
        DWORD dwMaxStrWrite
        DWORD dwMaxStrRead
        DWORD dwBaudRate
        unsigned char ucStopBits
        unsigned char ucParity
        unsigned char ucByteSize

    struct SSerialData:
        DWORD dwSize
        DWORD dwTimeout
        char cStop
        unsigned char bStop

    struct SPerfTime:
        double dRelativeTime
        double dUTCTime
