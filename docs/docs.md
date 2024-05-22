
### Описание задания

Этот проект заключается в создании чат-сервера и клиента, который будет функционировать аналогично команде `NetCat`, но с возможностью общения нескольких клиентов одновременно. Сервер должен поддерживать до 10 одновременных подключений и иметь следующие функции:

- Подключение клиентов к серверу через TCP.
- Идентификация клиентов по имени.
- Возможность отправки и получения сообщений клиентами.
- Информирование всех клиентов о присоединении или отключении других клиентов.
- Отправка всем клиентам истории сообщений при новом подключении.
- Пропуск пустых сообщений.
- Сообщения должны включать имя отправителя и время отправки.
- Указание порта для сервера через аргумент командной строки.

### Структура проекта

```
net-cat/
├── cmd/
│   └── net_cat/
│       ├── main.go              # Точка входа в приложение.
│       └── docs/
│           └── docs.md          # Документация проекта.
├── internal/
│   ├── router/
│   │   └── router.go            # Маршрутизация и обработка запросов (если требуется).
│   ├── server/
│   │   └── server.go            # Логика сервера: управление соединениями и сообщениями.
├── pkg/
│   ├── config/
│   │   └── config.go            # Конфигурация сервера (если требуется).
│   ├── logger/
│   │   └── logger.go            # Логирование (если требуется).
├── go.mod                       # Модульный файл Go для управления зависимостями проекта.
├── go.sum                       # Контрольные суммы для зависимостей проекта.
├── Makefile                     # Скрипт для сборки, запуска и тестирования проекта.
└── README.md                    # Основная документация проекта.
```

### Алгоритм выполнения

1. **Инициализация проекта**
    - Создайте проект и инициализируйте модуль Go.
    ```sh
    go mod init net-cat
    ```

2. **Создание `main.go`**
    - Создайте файл `cmd/net_cat/main.go` и реализуйте точку входа в приложение.
    ```go
    package main

    import (
        "fmt"
        "log"
        "net-cat/internal/server"
        "os"
        "strconv"
    )

    func main() {
        var port int
        var err error

        if len(os.Args) == 2 {
            port, err = strconv.Atoi(os.Args[1])
            if err != nil {
                fmt.Println("[USAGE]: ./TCPChat $port")
                return
            }
        } else {
            port = 8989
        }

        srv := server.NewServer(port)
        log.Printf("Listening on port :%d\n", port)
        srv.Start()
    }
    ```

3. **Реализация сервера**
    - Создайте файл `internal/server/server.go` и реализуйте логику сервера.
    ```go
    package server

    import (
        "bufio"
        "fmt"
        "log"
        "net"
        "strings"
        "sync"
        "time"
    )

    type Server struct {
        port          int
        clients       map[net.Conn]string
        messages      []string
        mu            sync.Mutex
        clientCounter int
    }

    func NewServer(port int) *Server {
        return &Server{
            port:    port,
            clients: make(map[net.Conn]string),
        }
    }

    func (s *Server) Start() {
        listener, err := net.Listen("tcp", fmt.Sprintf(":%d", s.port))
        if err != nil {
            log.Fatalf("Failed to start server: %v", err)
        }
        defer listener.Close()

        for {
            conn, err := listener.Accept()
            if err != nil {
                log.Printf("Failed to accept connection: %v", err)
                continue
            }

            s.mu.Lock()
            if s.clientCounter >= 10 {
                conn.Close()
                s.mu.Unlock()
                continue
            }
            s.clientCounter++
            s.mu.Unlock()

            go s.handleConnection(conn)
        }
    }

    func (s *Server) handleConnection(conn net.Conn) {
        defer func() {
            s.mu.Lock()
            delete(s.clients, conn)
            s.clientCounter--
            s.mu.Unlock()
            conn.Close()
        }()

        reader := bufio.NewReader(conn)
        conn.Write([]byte("Welcome to TCP-Chat!\n[ENTER YOUR NAME]: "))

        name, _ := reader.ReadString('\n')
        name = strings.TrimSpace(name)
        if name == "" {
            conn.Write([]byte("Invalid name. Connection closed.\n"))
            return
        }

        s.mu.Lock()
        s.clients[conn] = name
        for _, msg := range s.messages {
            conn.Write([]byte(msg + "\n"))
        }
        s.broadcast(fmt.Sprintf("%s has joined the chat", name))
        s.mu.Unlock()

        for {
            message, err := reader.ReadString('\n')
            if err != nil {
                s.broadcast(fmt.Sprintf("%s has left the chat", name))
                break
            }
            message = strings.TrimSpace(message)
            if message == "" {
                continue
            }
            timestamp := time.Now().Format("2006-01-02 15:04:05")
            fullMessage := fmt.Sprintf("[%s][%s]: %s", timestamp, name, message)

            s.mu.Lock()
            s.messages = append(s.messages, fullMessage)
            s.broadcast(fullMessage)
            s.mu.Unlock()
        }
    }

    func (s *Server) broadcast(message string) {
        for conn := range s.clients {
            conn.Write([]byte(message + "\n"))
        }
    }
    ```

4. **Добавление тестов**
    - Создайте тесты для сервера и других компонентов, если необходимо.
    ```go
    package server

    import (
        "net"
        "testing"
    )

    func TestServer(t *testing.T) {
        // Пример теста для сервера
        ln, err := net.Listen("tcp", ":8989")
        if err != nil {
            t.Fatalf("Failed to start test server: %v", err)
        }
        defer ln.Close()

        // Дополнительные тесты логики сервера
    }
    ```

5. **Добавление вспомогательных пакетов**
    - Создайте вспомогательные пакеты для конфигурации и логирования, если это необходимо.

6. **Создание Makefile**
    - Создайте Makefile для автоматизации сборки, запуска и тестирования проекта.
    ```Makefile
    .PHONY: all build run clean test

    all: build

    build:
        go build -o bin/tcp-chat ./cmd/net_cat

    run: build
        ./bin/tcp-chat

    clean:
        rm -rf bin

    test:
        go test ./...
    ```

7. **Документация**
    - Напишите документацию в файле `docs/docs.md`, описывающую проект, его архитектуру и инструкции по запуску.

### Пример документации (`docs/docs.md`)

```markdown
# TCP Chat

## Описание проекта

Этот проект реализует чат-сервер с поддержкой нескольких клиентов, работающий через TCP. Клиенты могут подключаться к серверу, отправлять сообщения и получать сообщения от других клиентов. Сервер поддерживает до 10 одновременных подключений.

## Структура проекта

```
net-cat/
├── cmd/
│   └── net_cat/
│       ├── main.go              # Точка входа в приложение.
│       └── docs/
│           └── docs.md          # Документация проекта.
├── internal/
│   ├── router/
│   │   └── router.go            # Маршрутизация и обработка запросов (если требуется).
│   ├── server/
│   │   └── server.go            # Логика сервера: управление соединениями и сообщениями.
├── pkg/
│   ├── config/
│   │   └── config.go            # Конфигурация сервера (если требуется).
│   ├── logger/
│   │   └── logger.go            # Логирование (если требуется).
├── go.mod                       # Модульный файл Go для управления зависимостями проекта.
├── go.sum                       # Контрольные суммы для зависимостей проекта.
├── Makefile                     # Скрипт для сборки, запуска и тестирования проекта.
└── README.md                    # Основная документация проекта.
```

## Установка и запуск

### Сборка проекта

Для сборки проекта используйте команду:
```sh
make build
```

### Запуск проекта

Для запуска проекта используйте команду:
```sh
make run
```

### Тестирование проекта

Для запуска тестов используйте команду:
```sh
make test
```

## Пример использования

Запуск сервера:
```sh
$ go run cmd/net_cat/main.go 8989
Listening on the port :8989
```

Подключение клиента:
```sh
$ nc localhost 

8989
Welcome to TCP-Chat!
[ENTER YOUR NAME]: John
[2024-05-22 15:03:43][John]:Hello everyone!
```

