-- 1procedimiento

drop procedure if exists emps_por_depto;

delimiter $$
create procedure emps_por_depto( )
begin
#variable para controlar cuando haya que salir del cursor (por ej. ya no haya más filas en el cursor)
declare finCursor boolean default false;
#variables para almacenar los datos de las consultas de los cursores (cuidado con tipo variables)
declare num_dept, dept, num_emp int;
declare nom_dept, apell varchar(25);
declare sal, com int;
declare fecha date;

-- Se crean dos Cursores, cada uno de ellos guarda la informacion que se necesitara despues:
declare c_departamentos cursor for
    select numero, nombre from departamentos order by numero;

declare c_empleados cursor for
    select cod_numero,nombre,fecha_ing,salario,
    if(comision is null, 0, comision) as comision,departamento
    from empleados order by departamento;

# declaramos handler para que automaticamente si ocurre un error de lectura en el Cursor, finCursor pasara a valer true.
declare continue handler for not found
    set finCursor = true;

# Se abren los cursores:
open c_departamentos;
open c_empleados;

# Se lee el primer departamento y empleado:
fetch c_departamentos into num_dept, nom_dept;
fetch c_empleados into num_emp,apell, fecha, sal, com,dept;

# Recorremos los departamentos
while (finCursor = false )
    do
    #Se imprime el departamento.
    select concat('Departamento: ', num_dept, ' - ', nom_dept) as 'DATOS DEPARTAMENTO';
 # Si el departamento del empleado es el mismo que el del empleado se muestran sus empleados
    while (num_dept = dept && finCursor = false )
        do
        # se imprimen empleados
        select concat( 'Nº Empleado: ',num_emp,', Empleado: ', apell, ' ,Fecha ingreso: ',fecha,', Salario: ', sal, ',
        Comision: ', com ) as 'DATOS EMPLEADO';
        fetch c_empleados into num_emp,apell, fecha, sal, com,dept;
    end while;
    # Pasamos a un nuevo departamento
    fetch c_departamentos into num_dept, nom_dept;
end while;
# Se cierran los cursores:
close c_empleados;
close c_departamentos;
End

-- 2procedimiento

drop procedure if exists deptos_emps;

delimiter $$
create procedure deptos_emps( in inicio int, in fin int)
begin
declare finCursor boolean default false;
#variable para contar el número de empleados de cada departamento
declare numero_empleados int default 0;
#variable para ir sumando los sueldos de los empleados de cada departamento
declare sueldo_dept int default 0;
declare num_dept, dept int;
declare nom_dept, apell varchar(25);
declare sal, com, total int;

-- Se crean dos Cursores, cada uno de ellos guarda la informacion que se necesitara despues:
declare c_departamentos cursor for
    select numero, nombre from departamentos where numero >= inicio && numero <= fin order by numero;
declare c_empleados cursor for
    select departamento, nombre, salario, if(comision is null, 0, comision) as comision,
    salario + if(comision is null, 0, comision) as total
    from empleados where departamento >= inicio && departamento <= fin order by departamento;

-- Automaticamente si ocurre un error de lectura en el Cursor, finCursor pasara a valer true.
declare continue handler for not found set finCursor = true;

-- Se abren los cursores:
open c_departamentos;
open c_empleados;

-- Se lee el primer departamento y empleado:
fetch c_departamentos into num_dept, nom_dept;
fetch c_empleados into dept, apell, sal, com, total;

-- Recorre los departamentos:
while finCursor = false
    do
    # inicializamos el sueldo de cada departamento a 0
    set sueldo_dept=0;
    #Se imprime el departamento.
    select concat('Departamento: ', num_dept, ' - ', nom_dept) as 'DATOS DEPARTAMENTO';
# Si el departamento del empleado es el mismo que el del empleado se muestra y se lee un nuevo empleado:
    while num_dept = dept && finCursor = false
        do
        set sueldo_dept = sueldo_dept + total; -- Suma sueldos.
        select concat( 'Empleado: ', apell, ', Salario: ', sal, ', Comision: ', com, ', Total sueldo: ', total ) as 'DATOS
        EMPLEADO';
        fetch c_empleados into dept, apell, sal, com, total;
        set numero_empleados = numero_empleados + 1; -- Cuenta empleados
        end while;
    # Se muestran los contadores:
    select concat( 'EMPLEADOS: ', numero_empleados, ' - TOTAL SUELDO: ', truncate(sueldo_dept, 3) ) as
    'TOTALES DEPARTAMENTO ';
    fetch c_departamentos into num_dept, nom_dept; -- Se le un nuevo departamento.
end while;
# Se cierran los cursores:
close c_empleados;
close c_departamentos;
end

--

CREATE DATABASE triggers;
USE triggers;

#Creación tabla artículos
CREATE TABLE articulos( id_articulo INT auto_increment primary key, titulo varchar(200) not null, autor varchar(25) not
null, fecha_pub date not null) ENGINE = InnoDB;

# Creación tabla que almacena los proceso realizados sobre la tabla "articulos" cada vez que realicemos una inserción,
actualización o borrado indicando en esta tabla la fecha, proceso realizado (inserción, modificación o borrado), número de
artículo sobre el que se ha realizado la operación.
CREATE TABLE proceso_articulos(id_proceso int auto_increment primary key, fecha date,usuario varchar(40), proceso
varchar(20), tituloantiguo varchar(200),titulonuevo varchar(200)) ENGINE = InnoDB;

#creación trigger para inserciones
CREATE TRIGGER insertar AFTER INSERT ON articulos FOR EACH ROW
    INSERT INTO proceso_articulos(fecha,usuario,proceso,tituloantiguo,titulonuevo)
    VALUES (NOW(),CURRENT_USER(),'inserción','',NEW.titulo);

#probemos el trigger
INSERT INTO articulos (id_articulo,titulo,autor,fecha_pub) VALUES (1,'primer registro para ejemplo de triggers en
MySQL','autor_x',NOW());
INSERT INTO articulos (id_articulo,titulo,autor,fecha_pub) VALUES (2,'segundo registro para ejemplo de triggers en
MySQL','autor_y',NOW());

select * FROM ARTICULOS;

#creación trigger para modificaciones
CREATE TRIGGER actualizar AFTER UPDATE ON articulos FOR EACH ROW
    INSERT INTO proceso_articulos(fecha,usuario,proceso,tituloantiguo,titulonuevo)
    VALUES (NOW(),CURRENT_USER(),'modificación',old.titulo,new.titulo);
update articulos set titulo='nuevo titulo ej. trigger' where id_articulo=1;

# creación trigger para el borrado
CREATE TRIGGER borrado AFTER DELETE ON articulos FOR EACH ROW
INSERT INTO proceso_articulos(fecha,usuario,proceso,tituloantiguo,titulonuevo)
VALUES (NOW(),CURRENT_USER(),'eliminación',OLD.titulo,'');
delete from articulos where id_articulo=1;

# consulta a la tabla log_articulos, luego de insertar, editar y eliminar registros en la tabla artículos:
SELECT * from proceso_articulos;
