//
//  CMTime+.c
//  
//
//  Created by kotan.kn on 8/10/R6.
//
#include"CMTime+.h"
__uint128_t const u128GCD(__uint128_t const x, __uint128_t const y) {
	return y == 0 ? x : u128GCD(y, x % y);
}
__int128_t const i128GCD(__int128_t const x, __int128_t const y) {
	return y == 0 ? x : i128GCD(y, x % y);
}
CMTime const CMTimeMul(CMTime const lhs, CMTime const rhs) {
	__int128_t const ln = lhs.value;
	__int128_t const ld = lhs.timescale;
	__int128_t const rn = rhs.value;
	__int128_t const rd = rhs.timescale;
	__int128_t value = ln * rn;
	__int128_t scale = ld * rd;
	{
		__int128_t const f = i128GCD(value, scale);
		value /= f;
		scale /= f;
	}
	__int128_t vn = MIN(value, INT64_MAX);
	__int128_t vd = value;
	__int128_t const vf = i128GCD(vn, vd);
	vn /= vf;
	vd /= vf;
	__int128_t sn = MIN(scale, INT32_MAX);
	__int128_t sd = scale;
	__int128_t const sf = i128GCD(sn, sd);
	sn /= sf;
	sd /= sf;
	if ( sn / sd < vd / vn ) {
		value *= sn;
		value /= sd;
		scale *= sn;
		scale /= sd;
	} else {
		value *= vd;
		value /= vn;
		scale *= vd;
		scale /= vn;
	}
	return CMTimeMake(value, scale);
}
CMTime const CMTimeDiv(CMTime const lhs, CMTime const rhs) {
	__int128_t const ln = lhs.value;
	__int128_t const ld = lhs.timescale;
	__int128_t const rn = rhs.value;
	__int128_t const rd = rhs.timescale;
	__int128_t value = ln * rd;
	__int128_t scale = ld * rn;
	value = 0 < scale ? value : -value;
	scale = 0 < scale ? scale : -scale;
	{
		__int128_t const f = i128GCD(value, scale);
		value /= f;
		scale /= f;
	}
	{
		__int128_t const n = MIN(scale, INT32_MAX);
		__int128_t const d = scale;
		__int128_t const f = i128GCD(n, d);
		value *= n / f;
		value /= d / f;
		scale *= n / f;
		scale /= d / f;
	}
	return CMTimeMake(value, scale);
}
CMTime const CMTimeMod(CMTime const lhs, CMTime const rhs) {
	__int128_t const ln = lhs.value;
	__int128_t const ld = lhs.timescale;
	__int128_t const rn = rhs.value;
	__int128_t const rd = rhs.timescale;
	__int128_t value = ( ln * rd ) % ( rn * ld );
	__int128_t scale = ( ld * rd );
	value = 0 < scale ? value : -value;
	scale = 0 < scale ? scale : -scale;
	{
		__int128_t const f = i128GCD(value, scale);
		value /= f;
		scale /= f;
	}
	{
		__int128_t const n = MIN(scale, INT32_MAX);
		__int128_t const d = scale;
		__int128_t const f = i128GCD(n, d);
		value *= d / f;
		value /= n / f;
		scale *= d / f;
		scale /= n / f;
	}
	return CMTimeMake(value, scale);
}
