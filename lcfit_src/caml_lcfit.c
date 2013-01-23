#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <gsl/gsl_errno.h>

#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "lcfit_tripod_c.h"

inline void check_model(value model)
{
  if(Wosize_val(model) / Double_wosize != TRIPOD_BSM_NPARAM) { \
    char err[200]; \
      sprintf(err, "Invalid model dimension: %lu [expected %zu]", \
          Wosize_val(model) / Double_wosize, \
          TRIPOD_BSM_NPARAM); \
      caml_invalid_argument(err); \
  }
}

/* OCaml records containing only floats are stored as arrays of doubles.
 * http://caml.inria.fr/pub/docs/manual-ocaml-4.00/manual033.html#htoc262 */
inline tripod_bsm_t convert_model(value model) {
    tripod_bsm_t m = {Double_field(model, 0),
                      Double_field(model, 1),
                      Double_field(model, 2),
                      Double_field(model, 3),
                      Double_field(model, 4),
                      Double_field(model, 5),
                      Double_field(model, 6),
                      Double_field(model, 7),
                      Double_field(model, 8) };
    return m;
}

CAMLprim value
caml_lcfit_tripod_ll(value model, value c_value, value tx_value)
{
    CAMLparam3(model, c_value, tx_value);

    double c = Double_val(c_value), tx = Double_val(tx_value);

    check_model(model);

    tripod_bsm_t m = convert_model(model);

    double result = lcfit_tripod_ll(c, tx, &m);
    CAMLreturn(caml_copy_double(result));
}

/**
 * model (tripod_bsm)
 * pts   Array of 3-tuples, containing (distal_bl, pendant_bl, log_like)
 *
 * See: lcfit.ml
 */
CAMLprim value
caml_lcfit_tripod_fit(value model, value pts)
{
    CAMLparam2(model, pts);
    assert(Tag_val(pts) == 0 && "Input should be array-ish");

    size_t n = Wosize_val(pts), i;

    /* Verify arguments */
    if(n < TRIPOD_BSM_NVARYING) {
        char err[200];
        sprintf(err, "Insufficient points to fit (%zu)", n);
        caml_invalid_argument(err);
    }
    check_model(model);

    double *dist_bl = malloc(sizeof(double) * n),
           *pend_bl = malloc(sizeof(double) * n),
           *ll      = malloc(sizeof(double) * n);

    for(i = 0; i < n; i++) {
        // Check input
        assert(Wosize_val(Field(pts, i)) == 3);
        assert(Tag_val(Field(Field(pts, i), 0)) == Double_tag);
        assert(Tag_val(Field(Field(pts, i), 1)) == Double_tag);
        assert(Tag_val(Field(Field(pts, i), 2)) == Double_tag);

        dist_bl[i] = Double_val(Field(Field(pts, i), 0));
        pend_bl[i] = Double_val(Field(Field(pts, i), 1));
        ll[i]      = Double_val(Field(Field(pts, i), 2));
    }

    tripod_bsm_t m = convert_model(model);

    int return_code = lcfit_tripod_fit_bsm(n, dist_bl, pend_bl, ll, &m);

    free(dist_bl);
    free(pend_bl);
    free(ll);

    if(return_code) {
        char err[300];
        sprintf(err, "lcfit_tripod_fit_bsm returned %d (%s)", return_code, gsl_strerror(return_code));
        caml_failwith(err);
    }

    CAMLlocal1(result);
    result = caml_alloc(TRIPOD_BSM_NPARAM * Double_wosize, Double_array_tag);
    double* m_arr = array_of_tripod_bsm(&m);
    for(i = 0; i < TRIPOD_BSM_NPARAM; i++)
        Store_double_field(result, i, m_arr[i]);
    free(m_arr);

    CAMLreturn(result);
}

CAMLprim value
caml_lcfit_tripod_jacobian(value model, value c_value, value tx_value)
{
    CAMLparam3(model, c_value, tx_value);

    check_model(model);
    tripod_bsm_t m = convert_model(model);

    double* jac = lcfit_tripod_jacobian(Double_val(c_value), Double_val(tx_value), &m);

    CAMLlocal1(result);
    result = caml_alloc(TRIPOD_BSM_NVARYING * Double_wosize, Double_array_tag);

    size_t i;
    for(i = 0; i < TRIPOD_BSM_NVARYING; ++i)
        Store_double_field(result, i, jac[i]);
    free(jac);
    CAMLreturn(result);
}