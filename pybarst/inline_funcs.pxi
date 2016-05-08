
''' The error codes of each of the external libraries (e.g. FTDI driver) gets
mapped into their own range.
'''

cdef int PY3 = 0

# 101 + 1-19 = (101 to 200)
cdef inline int FT_ERROR(int val) nogil:
    if val:
        return val + 100
    else:
        return 0

# 201 + 1-201 = (201 to 500)
cdef inline int RTV_ERROR(int val) nogil:
    if val:
        return -val + 200
    else:
        return 0

# 501 + 1-1200 = (501 to 1700)
cdef inline int MCDAQ_ERROR(int val) nogil:
    if val:
        return val + 500
    else:
        return 0

# 1001 + ? = (10001 to ?)
cdef inline int WIN_ERROR(int val) nogil:
    if val:
        return val + 10000
    else:
        return 0

cdef inline object tencode(object s):
    if not isinstance(s, bytes):
        return s.encode('utf8')
    return s

cdef inline object tdecode(object s):
    if PY3 and isinstance(s, bytes):
        return s.decode('utf8')
    return s
