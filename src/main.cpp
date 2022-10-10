#include "pico/stdlib.h"

int main() {
	const uint LED_PIN = 25;
	gpio_init(LED_PIN);
	gpio_set_dir(LED_PIN, GPIO_OUT);
	unsigned char blink = 1;
	while (true) {
		gpio_put(LED_PIN, blink);
		blink ^= 1;
		sleep_ms(500);
	}
}
