start cmd /k dalgs.exe 127.0.0.1  5000  127.0.0.1 5001 5002 5003
start cmd /min /k iex -S mix run -e "Communication.send(5005, 1);Communication.accept(5005)"
start cmd /min /k iex -S mix run -e "Communication.send(5006, 2);Communication.accept(5006)"
start cmd /min /k iex -S mix run -e "Communication.send(5007, 3);Communication.accept(5007)"
