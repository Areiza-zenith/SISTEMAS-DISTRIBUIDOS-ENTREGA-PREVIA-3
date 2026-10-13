/*
 * pi_leibniz.c
 * Calculo del numero PI con la serie de Leibniz usando MPI.
 * PI = 4 * SUM_{k=0}^{N-1} (-1)^k / (2k + 1)
 * Iteraciones: N = 9 x 10^9
 *
 * Compilar:  mpicc -O2 -o pi_leibniz pi_leibniz.c
 * Ejecutar:  mpirun -np <procesos> ./pi_leibniz
 */
#include <stdio.h>
#include <math.h>
#include "mpi.h"

#define N 9000000000LL               /* 9 x 10^9 iteraciones */
#define PI_REF 3.141592653589793238462643

int main(int argc, char *argv[])
{
    int rank, size, len;
    char host[MPI_MAX_PROCESSOR_NAME];
    long long inicio, fin, k;
    double suma_local = 0.0, suma_total = 0.0;
    double t_ini, t_fin;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(host, &len);

    /* Reparto por bloques: cada proceso calcula un rango contiguo */
    long long bloque = N / size;
    long long resto  = N % size;
    inicio = rank * bloque + (rank < resto ? rank : resto);
    fin    = inicio + bloque + (rank < resto ? 1 : 0);

    MPI_Barrier(MPI_COMM_WORLD);
    t_ini = MPI_Wtime();

    for (k = inicio; k < fin; k++) {
        double termino = 1.0 / (2.0 * (double)k + 1.0);
        suma_local += (k % 2 == 0) ? termino : -termino;
    }

    MPI_Reduce(&suma_local, &suma_total, 1, MPI_DOUBLE,
               MPI_SUM, 0, MPI_COMM_WORLD);
    t_fin = MPI_Wtime();

    printf("Proceso %d de %d en %s: k = [%lld, %lld)\n",
           rank, size, host, inicio, fin);

    if (rank == 0) {
        double pi = 4.0 * suma_total;
        printf("------------------------------------------\n");
        printf("Iteraciones      : %lld\n", N);
        printf("Procesos         : %d\n", size);
        printf("PI calculado     : %.15f\n", pi);
        printf("Error absoluto   : %.3e\n", fabs(pi - PI_REF));
        printf("Tiempo ejecucion : %.3f s\n", t_fin - t_ini);
    }

    MPI_Finalize();
    return 0;
}
