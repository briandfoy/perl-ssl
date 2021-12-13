#!/usr/bin/python
import sys, re

f = open(sys.argv[1], "r");
prg = f.read();
f.close();
stack = []
prg = (re.compile('#(?=.*).*',re.IGNORECASE).sub("",prg))
prg = (re.compile('[^abcdefghijklmnopqrstuvwxyz]*', re.IGNORECASE).sub("", prg))
prgPos = 0
shouldSkip = False

while prgPos<len(prg):
    if shouldSkip:
        shouldSkip = False
    else:
        char = prg[prgPos].lower()
        if char == "a":
            stack.insert(0,0)
        elif char == "b":
            stack.pop(0)
        elif char == "c":
            stack.insert(0,stack[0] - stack[1])
        elif char == "d":
            stack[0]-=1
        elif char == "e":
            stack.insert(0,stack[0] % stack[1])
        elif char == "f":
            print(chr(stack[0]),end="")
        elif char == "g":
            stack.insert(0,stack[0] + stack[1])
        elif char == "h":
            stack.insert(0,int(input("\nNumber: ")))
        elif char == "i":
            stack[0]+=1
        elif char == "j":
            stack.insert(0,ord(input("\nInput: ")[0]))
        elif char == "k":
            if stack[0]==0:
                shouldSkip = True
        elif char == "l":
            temp = stack[1]
            stack[1] = stack[0]
            stack[0] = temp
        elif char == "m":
            stack.insert(0,(stack[0] * stack[1]))
        elif char == "n":
            stack.insert(0,int(stack[0]==stack[1]))
        elif char == "o":
            stack.pop(stack[0])
        elif char == "p":
            stack.insert(0,stack[0] / stack[1])
        elif char == "q":
            stack.insert(0,stack[0])
        elif char == "r":
            stack.insert(0,len(stack))
        elif char == "s":
            temp = stack[stack[0]]
            stack[stack[0]] = stack[0]
            stack[0] = temp
        elif char == "t":
            if stack[0] == 0:
                opened = 0
                prgPos += 1
                while prgPos < len(prg):
                    if prg[prgPos] == "u" and opened == 0:
                           break
                    elif prg[prgPos] == "t":
                        opened += 1
                    elif prg[prgPos] == "u":
                        opened -= 1
                    prgPos += 1
        elif char == "u":
            if stack[0] != 0:
                closed = 0
                prgPos -= 1
                while prgPos >= 0:
                    if prg[prgPos] == "t" and closed == 0:
                        break
                    elif prg[prgPos] == "u":
                        closed += 1
                    elif prg[prgPos] == "t":
                        closed -= 1
                    prgPos -= 1
        elif char == "v":
            stack[0]+=5
        elif char == "w":
            stack[0]-=5
        elif char == "x":
            print(stack[0],end="")
        elif char == "y":
            stack = []
        elif char == "z":
            sys.exit(0)
        else:
            print("Invalid character:",char,"at",prgPos);
            sys.exit(0)
    prgPos+=1
