#!/bin/bash
# Ejecuta todo el laboratorio paso a paso. En cada pausa, tome la captura indicada.
cd "$(dirname "$0")"
sudo iptables-legacy -P FORWARD ACCEPT 2>/dev/null; sudo iptables-legacy -I FORWARD -j ACCEPT 2>/dev/null
mkdir -p resultados
OPC="-machinefile machines --mca btl self,tcp --mca btl_tcp_if_include 10.1.0.0/16 --mca oob_tcp_if_include 10.1.0.0/16"
M="docker exec -u mpiuser -w /home/mpiuser/codigo master"

pausa() { echo; read -r -p ">>> CAPTURA: $1  (presione Enter para continuar) " _; clear; }
titulo() { echo "=================================================================="; echo " $1"; echo "=================================================================="; }

clear
titulo "1. Construccion de la imagen y arranque de los tres nodos"
docker compose up -d --build
echo; docker compose ps
pausa "Imagen 7 - nodos master, nodo-0 y nodo-1 en ejecucion"

titulo "2. Red interna numeroPI"
docker network inspect numeroPI --format '{{range .Containers}}{{.Name}}  ->  {{.IPv4Address}}{{"\n"}}{{end}}'
echo; docker exec master ip -4 addr show | grep -E "^[0-9]|inet"
pausa "Imagen 8 - direcciones IP de la red numeroPI y del master"

titulo "3. Prueba de conectividad desde el master"
$M ping -c 4 compute-0-0
$M ping -c 4 compute-0-1
pausa "Imagen 9 - ping del master a compute-0-0 y compute-0-1"

titulo "4. Comandos de administracion del cluster"
$M bash -c 'printf "master slots=1\ncompute-0-0 slots=1\ncompute-0-1 slots=1\n" > machines; cat machines'
echo; $M ssh compute-0-0 "hostname; uptime"
$M ssh compute-0-1 "hostname; uptime"
echo; docker stats --no-stream master nodo-0 nodo-1
pausa "Imagen 11 - archivo machines, ssh a los nodos y docker stats"

titulo "5. Compilacion y ejecucion de holamundo.c"
$M mpicc -o holamundo holamundo.c && echo "mpicc -o holamundo holamundo.c  [OK]"
$M mpirun -np 3 $OPC ./holamundo | tee resultados/holamundo.txt
pausa "Imagen 13 - ejecucion de holamundo con 3 procesos"

titulo "6. Compilacion de pi_leibniz.c"
$M mpicc -O2 -o pi_leibniz pi_leibniz.c -lm && echo "mpicc -O2 -o pi_leibniz pi_leibniz.c -lm  [OK]"
for p in 1 2 3; do
  echo; titulo "7.$p Calculo de PI con $p proceso(s)"
  $M mpirun -np $p $OPC ./pi_leibniz | tee resultados/pi_${p}_procesos.txt
  pausa "Imagen $((16 + p)) - ejecucion con $p procesador(es)"
done

titulo "Resumen de tiempos"
grep -H "Tiempo" resultados/pi_*_procesos.txt | tee resultados/resumen.txt
echo
echo "Listo. Los resultados quedaron en la carpeta resultados/."
echo "Para apagar el cluster:  docker compose down"
