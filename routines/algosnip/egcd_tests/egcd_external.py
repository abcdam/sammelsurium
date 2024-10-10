#!/usr/bin/python
import numpy as np
import galois as g
import libnum as ln
import gmpy2 as gp

# all functions return gcd(a,b) in the form of (gcd,x,y),
#   where x,y are the coefficients of gcd(a,b) = xa+yb

# nearly everything done in one matrix object
def egcd_matrix(a,b):
    op_matrix = np.array([[a,b],[1,0],[0,1]],dtype=int)
    while op_matrix[0,1] != 0:
        q = op_matrix[0,0] // op_matrix[0,1]
        op_matrix = op_matrix[:,[1,0]]
        op_matrix[:,1] -= q*op_matrix[:,0]
    if op_matrix[0,0] < 0: op_matrix *= -1
    return tuple(op_matrix[:,0])

# using numpy arrays instead of matrix
def egcd_copy(a,b):
    a_triplet = np.array([a,1,0],dtype=int)
    b_triplet = np.array([b,0,1],dtype=int)
    while b_triplet[0] != 0:
        q = a_triplet[0] // b_triplet[0]
        temp=b_triplet.copy()
        b_triplet= a_triplet - q*b_triplet
        a_triplet = temp.copy()
    if a_triplet[0] < 0: a_triplet *= -1
    return tuple(a_triplet)

def egcd_galois(a,b):
    return g.egcd(a,b)

def egcd_libnum(a,b):
    xgcd = ln.xgcd(a,b)
    return (xgcd[2],*xgcd[:2])

def egcd_gmpy2(a,b):
    return tuple([int(x) for x in gp.gcdext(a,b)])