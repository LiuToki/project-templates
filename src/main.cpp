#include <iostream>
#include "pico/stdlib.h"

int main() {
    setup_default_uart();
	std::cout <<"Hello, world!" << std::endl;
    return 0;
}
