using TensorKit, Convex
using Yao
using MosekTools,SCS

d = 2 # spin physical dimension
D = 5 # bond dimension (for coarse graining the states)
# 1d translational invariant hamiltonian
h = mat((kron(X,X) + kron(Y,Y) + kron(Z,Z))/4)
n = 6 # maximum site of reduced density matrix

ρ3 = ComplexVariable(d^3,d^3)
A = randn(ComplexF64,D,d,D) 

@tensor W2[j,l,i,k] := A[j,i,a] * A[a,k,l]

W2 = reshape(W2,D^2,d^2)

R2 = reshape(A,D,d*D) 
L2 = reshape(A,d*D,D)'

iremain = Diagonal(ones(ComplexF64,d*D)) 
i2mat = mat(I2)

ωs = fill(ComplexVariable(d^2*D^2,d^2*D^2),n-3)

constraints = [
    tr(ρ3) == 1.0,
    ρ3 ⪰ 0,
    # [tr(ω) = 1.0 for ω in ωs]..., # automatically satisfied
    [ω ⪰ 0 for ω in ωs]...,
    partialtrace(ρ3, 1, d*ones(Int64,3)) == partialtrace(ρ3, 3, d*ones(Int64,3)), 
    kron(W2,i2mat) * ρ3 * kron(W2,i2mat)' == partialtrace(ωs[1],1,[d,D^2,d]),
    kron(i2mat,W2) * ρ3 * kron(i2mat,W2)' == partialtrace(ωs[1],3,[d,D^2,d])
]

for ii in 2:n-3
    push!(constraints, kron(L2,iremain) * ωs[ii-1]  * kron(L2,iremain)' == partialtrace(ωs[ii],1,[d,D^2,d]))
    push!(constraints, kron(iremain,R2) * ωs[ii-1]  * kron(iremain,R2)' == partialtrace(ωs[ii],3,[d,D^2,d]))
end

problem = minimize(real(tr(kron(h,mat(I2))*ρ3)), constraints)

solve!(problem, Mosek.Optimizer)
problem.optval