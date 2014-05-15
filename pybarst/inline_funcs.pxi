
''' The error codes of each of the external libraries (e.g. FTDI driver) gets
mapped into their own range.
'''
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

# 1001 + ? = (1001 to ?)
cdef inline int WIN_ERROR(int val) nogil:
    if val:
        return val + 1000
    else:
        return 0
