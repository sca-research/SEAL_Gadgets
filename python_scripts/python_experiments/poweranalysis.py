import scipy.stats as stats


def calculate_nested_f_test_parameter(alpha=0.01, power=None, df1=1, df2=100, effect_size=0.02):
    f_critical = stats.f.ppf(1 - alpha, df1, df2)
    print(f"f_critical: {f_critical}")
    if power is None:
        lambda_ = effect_size * (df2 + df1 + 1)     # power = 1 - beta
        return 1 - stats.ncf.cdf(f_critical, df1, df2, lambda_)     # cdf**-1
    elif effect_size is None:
        lambda_ = stats.ncf.ppf(power, df1, df2, f_critical)    # effect size
        return lambda_ / (df2 + df1 + 1)
    else:
        raise ValueError("Invalid parameter to calculate")


z_f = 10
z_r = 9
N = 1000
alpha = 10 ** (-5)    # th = 5
es = effect_size = 0.01
df1 = z_f - z_r
df2 = N - z_f
result = calculate_nested_f_test_parameter(alpha=alpha, power=None, df1=df1, df2=df2, effect_size=es)
print(f"Power: {result}, alpha: {alpha}, ES: {es}, z_f: {z_f}, z_r: {z_r}, N: {N}")
