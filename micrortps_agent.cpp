// Copyright 2017 Proyectos y Sistemas de Mantenimiento SL (eProsima).
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <micrortps/agent/transport/UARTServer.hpp>
#include <micrortps/agent/transport/UDPServer.hpp>
#include <micrortps/agent/transport/TCPServer.hpp>
#include <micrortps/agent/Root.hpp>
#include <termios.h>

int main(int argc, char** argv)
{
    eprosima::micrortps::XRCEServer* server;
    bool initialized = false;

    if(argc == 3 && strcmp(argv[1], "uart") == 0)
    {
        std::cout << "UART agent initialization... ";
        eprosima::micrortps::UARTServer* uart_server = new eprosima::micrortps::UARTServer();
        if (0 == uart_server->launch((uint8_t)atoi(argv[2]), 0x00))
        {
            initialized = true;
            server = uart_server;
        }
        std::cout << ((!initialized) ? "ERROR" : "OK") << std::endl;
    }
    else if (argc == 2 && strcmp(argv[1], "pseudo-uart") == 0)
    {
        std::cout << "Pseudo-UART initialization... ";

        /* Open pseudo-terminal. */
        char* dev;
        int fd = posix_openpt(O_RDWR | O_NOCTTY);
        if (-1 != fd)
        {
            if (grantpt(fd) == 0 && unlockpt(fd) == 0 && (dev = ptsname(fd)))
            {
                struct termios attr;
                tcgetattr(fd, &attr);
                cfmakeraw(&attr);
                tcflush(fd, TCIOFLUSH);
                tcsetattr(fd, TCSANOW, &attr);
            }
        }

        /* Launch server. */
        eprosima::micrortps::UARTServer* uart_server = new eprosima::micrortps::UARTServer();
        if (0 == uart_server->launch(fd, 0x00))
        {
            initialized = true;
            server = uart_server;
        }

        if (initialized)
        {
            std::cout << "OK" << std::endl;
            std::cout << "Device: " << dev << std::endl;
        }
        else
        {
            std::cout << "ERROR" << std::endl;
        }
    }
    else if(argc ==3 && strcmp(argv[1], "udp") == 0)
    {
        std::cout << "UDP agent initialization... ";
        eprosima::micrortps::UDPServer* udp_server = new eprosima::micrortps::UDPServer();
        if (0 == udp_server->launch((uint16_t)atoi(argv[2])))
        {
            initialized = true;
            server = udp_server;
        }
        std::cout << ((!initialized) ? "ERROR" : "OK") << std::endl;
    }
    else if(argc ==3 && strcmp(argv[1], "tcp") == 0)
    {
        std::cout << "TCP agent initialization... ";
        eprosima::micrortps::TCPServer* tcp_server = new eprosima::micrortps::TCPServer();
        if (0 == tcp_server->launch((uint16_t)atoi(argv[2])))
        {
            initialized = true;
            server = tcp_server;
        }
        std::cout << ((!initialized) ? "ERROR" : "OK") << std::endl;
    }
    else
    {
        std::cout << "Error: Invalid arguments." << std::endl;
    }

    if(initialized)
    {
        eprosima::micrortps::Agent& micrortps_agent = eprosima::micrortps::root();
        micrortps_agent.init(server);
        micrortps_agent.run();
    }
    else
    {
        std::cout << "Help: program <command>" << std::endl;
        std::cout << "List of commands:" << std::endl;
        std::cout << "    uart <fd>" << std::endl;
        std::cout << "    pseudo-uart" << std::endl;
        std::cout << "    udp <local_port>" << std::endl;
        std::cout << "    tcp <local_port>" << std::endl;
    }
    return 0;
}
