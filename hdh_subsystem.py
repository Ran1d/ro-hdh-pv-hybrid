# HDH subsystem code
# Inputs
m_dot_hot = 0.5  # "Hot fluid mass flow rate [kg/s]"
cp_hot = 4.18    # "Specific heat of hot fluid [kJ/(kg.K)]"
T_hot_in = 70    # "Inlet temperature of hot fluid [°C]"
T_hot_out = 45   # "Outlet temperature of hot fluid [°C]"
P_atm = 101.325  # "Atmospheric pressure [kPa]"
m_dot_cold = 1.5 # "Cold fluid mass flow rate [kg/s]"
cp_cold = 4.18   # "Specific heat of cold fluid [kJ/(kg.K)]"
T_cold_in = 45   # "Inlet temperature of cold fluid [°C]"
T_in_a = 25
m_dot_a = 7

# Energy balance for the hot fluid
Q_hot = m_dot_hot * cp_hot * (T_hot_in - T_hot_out)

# Energy balance for the cold fluid
# Note: The original formula T_cold_out = (Q_hot/( m_dot_cold * cp_cold))*.9+ T_cold_in
# is an approximation or simplified model.
T_cold_out = (Q_hot / (m_dot_cold * cp_cold)) * 0.9 + T_cold_in
T_out_a = T_cold_out * 1

# Functions from an external library (e.g., CoolProp or a custom module) are assumed:
# p_sat(Fluid, T=Temp)
# humrat(Fluid, T=Temp, R=RelativeHumidity, P=Pressure)
# enthalpy(Fluid, T=Temp, P=Pressure)
# enthalpy_vaporization(Fluid, T=Temp)

# Placeholder functions for the assumed library calls
def p_sat(fluid, T):
    # Placeholder: In a real Python script, this would call a library function
    # or use a correlation to get saturation pressure.
    # Returning a dummy value for structure.
    return 3.169 # kPa at 25C for water (approx)

def humrat(fluid, T, R, P):
    # Placeholder: Returns humidity ratio (kg_water/kg_air)
    return 0.02 # kg_water/kg_air (approx)

def enthalpy(fluid, T, P):
    # Placeholder: Returns enthalpy (kJ/kg)
    return 100.0 # kJ/kg (approx)

# Calculations using the assumed functions
w_dry = 0.1
w_humid = 1.0

P_hsati = p_sat("Water", T=T_in_a)
P_hsato = p_sat("Water", T=T_out_a)

x_hin = 0.622 * (w_dry * P_hsati) / (P_atm - (w_dry * P_hsati))
x_hout = 0.622 * (w_humid * P_hsato) / (P_atm - (w_humid * P_hsato))

omega = humrat("AirH2O", T=T_in_a, R=w_dry, P=P_atm)

# "m_dot_fw = m_dot_a * (w_humid - w_dry)"
m_dot_fw = m_dot_a * (x_hout - x_hin) # "Condensation rate [kg/s]"

h_dot_cold = enthalpy("Water", T=T_cold_out, P=P_atm)
# "h_latent=enthalpy_vaporization(Water,T=T_cold_out)"
h_out_h = enthalpy("AirH2O", T=T_out_a, R=w_humid, P=P_atm)
h_in_h = enthalpy("AirH2O", T=T_in_a, R=w_dry, P=P_atm)

m_dot_bw = m_dot_cold - m_dot_fw
h_bw = ((m_dot_cold * h_dot_cold + m_dot_a * (h_out_h - h_in_h)) / m_dot_bw)
# " m_dot_fw * h_latent"

# "HDH System: Dehumidification Process"
T_in = T_out_a  # "Inlet air temperature [°C]"
RH_in = w_humid # "Inlet air relative humidity [%]"
T_out = T_in - 25 # "Outlet air temperature [°C]"

# "Convert airflow rate to mass flow rate"
m_dot_air = m_dot_a # "Mass flow rate of air [kg/s]"

# "Calculate specific humidity at inlet and outlet using psychrometric properties"
P_sat = p_sat("Water", T=T_out)
omega_in = humrat("AirH2O", T=T_in, R=1, P=P_atm)
omega_out = humrat("AirH2O", T=T_out, R=1, P=P_atm)

x_in = 0.622 * (P_hsato) / (P_atm - P_hsato) # "Specific humidity at inlet [kg_water/kg_air]"
x_out = 0.622 * (P_sat) / (P_atm - P_sat) # "Specific humidity at outlet [kg_water/kg_air]"

m_dot_dw = m_dot_a * (omega_in - x_out)

# "Calculate enthalpy at inlet and outlet"
h_in = 1.005 * T_in + x_in * (2501 + 1.84 * T_in) # "Enthalpy at inlet [kJ/kg_air]"
h_out = 1.005 * T_out + x_out * (2501 + 1.84 * T_out) # "Enthalpy at outlet [kJ/kg_air]"

m_dot_cld = m_dot_cold / 0.3
h_inn = enthalpy("AirH2O", T=T_in, R=0.9, P=P_atm)
h_outt = enthalpy("AirH2O", T=T_out, R=1, P=P_atm)

# "Cooling rate required"
Q = m_dot_air * (h_inn - h_outt) * 0.7 # "Cooling rate [kW]"

T_sw_in = 25
T_sw_out = (Q / (m_dot_cld * cp_cold)) + T_sw_in

# Example of printing a result
# print(f"Hot fluid heat transfer rate (Q_hot): {Q_hot} kJ/s")
# print(f"Calculated T_cold_out: {T_cold_out} °C")
# print(f"Calculated Cooling rate (Q): {Q} kW")
