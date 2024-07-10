# C implementations of the gadgets 

Each gadget is encapsulated in its own directory including a header file (Gadget_name.h) and two source files (Gadget_name.c, main.c).


The number of ```Mask_ORD``` (number of shares = Mask_ORD+1) can be changed.

can be adjusted directly in the gadget's header file (Gadget_name.h).


For compilation:

Using the **GCC compiler**
```
gcc main.c Gadget_name.c
```

For running:
```
./a.out
```

### Example:
From **ISW** directory:

```
gcc main.c ISW.c
```
**a.out** will be generated, 
For running:
```
./a.out
```

