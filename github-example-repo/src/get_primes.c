#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

// Function to check if a number is prime
bool isPrime(int num) {
    if (num <= 1) {
        return false; // Numbers less than or equal to 1 are not prime
    }

    for (int i = 2; i * i <= num; i++) {
        if (num % i == 0) {
            return false; // If num is divisible by i, it's not prime
        }
    }

    return true; // num is prime
}

// Function to find n primes
void findPrimes(int n) {
    int count = 0;
    int num = 2;

    printf("RESULT: %d primes ", n);
    while (count < n) {
        if (isPrime(num)) {
            printf("%d ", num);
            count++;
        }
        num++;
    }

    printf("\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <n>\n", argv[0]);
        return 1;
    }

    // Convert command-line argument to integer
    int n = atoi(argv[1]);

    findPrimes(n);

    return 0;
}