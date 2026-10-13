# Clúster HPC con MPI – Cálculo de PI (Entrega Final, Sistemas Distribuidos)

Clúster de tres nodos (`master`, `nodo-0` → compute-0-0, `nodo-1` → compute-0-1) construido con
Docker Compose dentro de GitHub Codespaces.

- Red interna `numeroPI` (10.1.0.0/16, sin salida a Internet): master 10.1.1.1, compute-0-0 10.1.255.254, compute-0-1 10.1.255.253
- Red pública `publica` (NAT): solo el master

## Contenido
| Archivo | Descripción |
|---|---|
| `Dockerfile` | Imagen de cada nodo: Ubuntu 22.04 + Open MPI + SSH |
| `docker-compose.yml` | Los tres nodos y las dos redes |
| `codigo/holamundo.c` | Programa de prueba MPI |
| `codigo/pi_leibniz.c` | Cálculo de PI (Leibniz, 9×10^9 iteraciones) |
| `ejecutar.sh` | Ejecuta todo el laboratorio y se detiene en cada captura |

## Cómo ejecutarlo
1. En el repositorio: **Code → Codespaces → "…" → New with options → Machine type: 4-core → Create codespace**.
2. En la terminal del Codespace:
   ```bash
   chmod +x ejecutar.sh
   ./ejecutar.sh
   ```
3. En cada pausa tome la captura indicada y presione Enter.
4. Los resultados quedan en la carpeta `resultados/`.
5. Para apagar el clúster: `docker compose down`. Luego detenga el Codespace (Codespaces → Stop).

## Ejecución manual dentro del master
```bash
docker exec -it -u mpiuser -w /home/mpiuser/codigo master bash
OPC="-machinefile machines --mca btl self,tcp --mca btl_tcp_if_include 10.1.0.0/16 --mca oob_tcp_if_include 10.1.0.0/16"
mpirun -np 3 $OPC ./pi_leibniz
```
