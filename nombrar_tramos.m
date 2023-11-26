function nombres_tramos=nombrar_tramos(A,cant_ramales) % Funcion que recibe una matriz A y nombra los tramos.
% A: Matriz Adyacencia cargado en Excel
Ntr=length(A(1,:)); %nro de Tramos.
%% Crear un array tipo cell para cargar nombre de tramos
nombres_tramos = cell(1, Ntr); % Inicializar el cell array
%% Llenar el cell array con nombres de tramos
    for i = 1:Ntr
        if i <= Ntr - cant_ramales
            nombres_tramos{i} = ['T ' num2str(i)];
        else
            nombres_tramos{i} = [num2str(i)];
        end
    end
end