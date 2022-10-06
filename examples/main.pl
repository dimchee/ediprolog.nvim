factorial(A, F) :- A > 0, factorial(A-1, F1), F = A * F1.
factorial(A, 1) :- A =:= 0.

% ?- factorial(3, S).
