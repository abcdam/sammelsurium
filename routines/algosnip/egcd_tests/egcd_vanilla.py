#!/usr/bin/python

# all functions return gcd(a,b) in the form of (gcd,x,y),
#   where x,y are the coefficients of gcd(a,b) = xa+yb

# egcd implementations using python built-ins

def egcd_tuple(a,b):
    a_triplet = (a,1,0)
    b_triplet = (b,0,1)
    while b_triplet[0] != 0:
        q = a_triplet[0] // b_triplet[0]
        a_triplet,b_triplet = b_triplet, tuple(map(lambda xi,yi: xi - q*yi,a_triplet,b_triplet))
    if a_triplet[0] < 0: a_triplet = tuple(-1*x for x in a_triplet)
    return a_triplet

def egcd_ziplist(a,b):
    aList = [a,1,0]
    bList = [b,0,1]
    while bList[0] != 0:
        q = aList[0] // bList[0]
        aList,bList = bList,[ai-q*bi for ai,bi in zip(aList,bList)]
    if aList[0] < 0: aList = [-1*x for x in aList]
    return tuple(aList)

def egcd_lambdalist(a,b):
    aList = [a,1,0]
    bList = [b,0,1]
    while bList[0] != 0:
        q = aList[0] // bList[0]
        aList,bList = bList, [*map(lambda xi,yi: xi - q*yi,aList,bList)]
    if aList[0] < 0: aList = [-1*x for x in aList]
    return tuple(aList)

def egcd_var(a,b):
    x1,x2,y1,y2 = 1,0,0,1
    while b != 0:
        q = a // b
        a,x1,y1,b,x2,y2 = b,x2,y2,a-q*b,x1-q*x2,y1-q*y2
    if a < 0: a,x1,y1 = -a,-x1,-y1
    return (a,x1,y1)