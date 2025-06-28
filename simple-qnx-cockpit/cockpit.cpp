#include <iostream>
#include <unistd.h>
#include <iomanip>

int main() {
    int speed = 0;
    bool increasing = true;
    int elapsed_time = 0;
    const int MAX_TIME = 20;
    
    std::cout << "Starting QNX Vehicle Cockpit..." << std::endl;
    sleep(1);
    
    while (elapsed_time < MAX_TIME) {
        // Clear screen
        std::cout << "\033[2J\033[H";
        
        std::cout << "=== QNX Vehicle Cockpit ===" << std::endl;
        std::cout << std::endl;
        
        // Speed display
        std::cout << "Speed: " << std::setw(3) << speed << " km/h" << std::endl;
        
        // Simple ASCII speed meter
        std::cout << "┌────────────────────────────┐" << std::endl;
        std::cout << "│";
        
        int bars = (speed * 28) / 200;
        for (int i = 0; i < 28; i++) {
            std::cout << (i < bars ? "█" : " ");
        }
        std::cout << "│" << std::endl;
        std::cout << "└────────────────────────────┘" << std::endl;
        std::cout << "0                        200" << std::endl;
        
        // Status
        std::cout << std::endl << "Status: ";
        if (speed == 0) std::cout << "PARKED";
        else if (speed < 50) std::cout << "CITY";
        else if (speed < 100) std::cout << "HIGHWAY";
        else std::cout << "HIGH SPEED";
        
        std::cout << std::endl << std::endl;
        std::cout << "Auto-exit in " << (MAX_TIME - elapsed_time) << " seconds" << std::endl;
        
        // Update speed
        if (increasing) {
            speed += 5;
            if (speed >= 120) increasing = false;
        } else {
            speed -= 3;
            if (speed <= 0) increasing = true;
        }
        
        sleep(1);
        elapsed_time++;
    }
    
    std::cout << "\nCockpit shutting down..." << std::endl;
    
    return 0;
}