#include <stdio.h>
#include <stdlib.h>
#include <stdlib.h>

__global__ void dc_kernel(int n, int *R, int *C, double *dc);

int main(int argc, char const *argv[]) {
    
    /* File che rappresentano il grafo in formato RCE */
    FILE *R = fopen("data/row_offsets.dat", "r");
    FILE *C = fopen("data/column_indices.dat", "r");

    int n, r_size, c_size;
    int *h_r, *h_c;
    int *d_r, *d_c;
    double *h_dc, *d_dc;

    /* Input: numero di nodi e archi del grafo */
    printf("Inserire numero di nodi: ");
    scanf("%d", &n);
    r_size = n + 1;

    printf("Inserire numero di archi: ");
    scanf("%d", &c_size);

    /* Allocazione strutture dati host */
    h_r = (int*)malloc(r_size * sizeof(int));
    h_c = (int*)malloc(c_size * sizeof(int));
    h_dc = (double*)malloc(n * sizeof(int));

    /* Allocazione strutture dati device */
    cudaMalloc((void **) &d_r, r_size * sizeof(int));
    cudaMalloc((void **) &d_c, c_size * sizeof(int));
    cudaMalloc((void **) &d_dc, n * sizeof(double));

    /* Leggo da file il columns indices ed il row offsets array */
    for (int i = 0; i < r_size; i++) {
        fscanf(R, "%d\n", &h_r[i]);
    }
    for (int i = 0; i < c_size; i++) {
        fscanf(C, "%d\n", &h_c[i]);
    }

    /* Copia da host a device */
    cudaMemcpy(d_r, h_r, r_size * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_c, h_c, c_size * sizeof(int), cudaMemcpyHostToDevice);

    /* Configurazione del Kernel */
    dim3 blockDim(64);
    dim3 gridDim((n + blockDim.x - 1) / blockDim.x);

    /* Invocazione del kernel */
    dc_kernel<<<gridDim, blockDim>>>(n, d_r, d_c, d_dc);

    /* Copia dei risultati da device a host */
    cudaMemcpy(h_dc, d_dc, n * sizeof(double), cudaMemcpyDeviceToHost);

    /* Stampa dei risultati */
    printf("Degree Centrality:\n");
    for (int i = 0; i < n; i++) {
        printf("Score %d: %f\n", i+1, h_dc[i]);
    }


    return 0;
}

__global__ void dc_kernel(int n, int *R, int *C, double *dc) {
    int idx = threadIdx.x;

    if (idx < n) {
        dc[idx] = (double) (R[idx+1] - R[idx]) / (n - 1);
    }
}