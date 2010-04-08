(%
 % rowl - generation 2
 % Copyright (C) 2010 nineties
 %
 % $Id: alloc.rl 2010-04-08 18:17:16 nineties $
 %)

(% memory allocation %);

import sys;

BlockSize => 1048576; (% 1MB %)
BlockMask => 1048575; (% BlockSize - 1 %)
MaxBlocks => 4096; (% 4GB/BlockSize = 4096 %)

block_used: static_array(0, MaxBlocks);
next_addr: 0;
num_block: 0;
free_first: 0;
free_last: 0;

(% allocate memory block with size of BlockSize %)
alloc_block: () {
    addr: mmap2(0, 2*BlockSize);
    slop: addr & BlockMask;

    munmap(addr, slop);
    if (slop > 0) {
        munmap(addr + slop + BlockSize, BlockSize - slop);
    };
    addr += slop;
    return addr;
};

(% allocate memory block with size of BlockSize and set free_first and free_last %)
alloc_block_fast: () {
    if (num_block >= MaxBlocks) {
        exit(1);
    };
    addr: 0;
    if (next_addr == 0) {
        addr = alloc_block();
    } else {
        addr = mmap2(next_addr, BlockSize);
        if (addr & BlockMask != 0) {
            munmap(addr, BlockSize);
            addr = alloc_block();
        }
    };
    next_addr = addr + BlockSize;
    block_used[addr/BlockSize] = 1;
    free_first = addr;
    free_last  = next_addr;
};

export
alloc: (size) {
    if (size == 0) {
        return 0;
    } else if (free_first + size >= free_last) {
        alloc_block_fast();
    };
    ret : free_first;
    free_first += size;
    return ret;
};
