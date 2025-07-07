CREATE TABLE status (
    id serial primary key,
    name varchar(32),
    version integer DEFAULT 0
);

INSERT INTO status (name) values ('Habilitado');
INSERT INTO status (name) values ('Deshabilitado');
INSERT INTO status (name) values ('Bloqueado');
INSERT INTO status (name) values ('Eliminado');


create table unit_measure (
	id serial primary key,
	name varchar(32) not null,
	code varchar(8) not null
);


INSERT INTO unit_measure (name, code) VALUES
('Caja', 'CAJA'),
('Paleta', 'PALETA'),
('Metros Cuadrados', 'M2'),
('Kilogramos', 'KG'),
('Unidad', 'UNI'),
('Talla', 'TALLA'),
('Centimetros', 'cm'),
('Bulto', 'BULTO'),
('Docena', 'DOCENA');


-- Tabla Categorias: Almacena las categorías pr incipales de productos
CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    code VARCHAR(32), -- CEPI (Cerámica Piso) o CEPA (Cerámica Pared)
    name VARCHAR(100), -- Nombre completo: 'CERAMICA PISO' o 'CERAMICA PARED'
    description VARCHAR(200), -- Descripción detallada de la categoría
    category_id INTEGER,
    status_id INTEGER REFERENCES status (id) DEFAULT 1
);

ALTER TABLE category
    ADD CONSTRAINT fk_category_status FOREIGN KEY (status_id) REFERENCES status (id);

ALTER TABLE category
    ADD CONSTRAINT fk_category_category FOREIGN KEY (category_id) REFERENCES category (id);

-- Tabla Calidades: Define los niveles de calidad de los productos
CREATE TABLE quality (
    id SERIAL PRIMARY KEY,
    code VARCHAR(1), -- 1, 2, 3 (Para formar parte del código del producto)
    name VARCHAR(50) -- 1ERA, 2DA, 3ERA (Nombre descriptivo de la calidad)
);

-- Tabla Monedas: Define las monedas disponibles para precios
CREATE TABLE currency (
    id SERIAL PRIMARY KEY, -- 1=BS, 2=USD
    code VARCHAR(3), -- BS, USD
    name VARCHAR(50) -- Bolívares, Dólares Americanos
);

-- Tabla Formatos: Dimensiones disponibles para los productos
CREATE TABLE formats (
    id SERIAL PRIMARY KEY,
    dimensions VARCHAR(20), -- 33x33, 25x40 (dimensiones en centímetros)
    description VARCHAR(100), -- Descripción detallada del formato
    unit_measure_id INTEGER REFERENCES unit_measure (id) -- FK a unidad de medida
);

-- Tabla Modelos: Diferentes modelos de productos
CREATE TABLE model (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20), -- Código único del modelo (ej: CAICO, MACIZO, etc.)
    name VARCHAR(100) -- Nombre descriptivo del modelo
);

-- Tabla Marcas: Marcas de los productos
CREATE TABLE make (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) -- Nombre de la marca (ej: CERAMICA VIZCAYA)
);

-- Tabla Productos: Tabla principal de productos
CREATE TABLE products (
    id serial primary key,
    code VARCHAR(20) not NULL unique, -- Formato: CEPI/CEPA + 1/2/3 + 0001
    category_id INTEGER REFERENCES category (id) not null, -- FK a categoría (CEPI/CEPA)
    quality_id INTEGER REFERENCES quality (id) not null, -- FK a calidad (1ERA/2DA/3ERA)
    numeric_seq INTEGER, -- Número secuencial (0001, 0002, etc.)
    format_id INTEGER REFERENCES formats (id), -- FK al formato (33x33, 25x40)
    model_id INTEGER REFERENCES model (id), -- FK al modelo
    make_id INTEGER REFERENCES make (id), -- FK a la marca
    name VARCHAR(200) not null unique, -- Nombre completo del producto
    unit_measure_id INTEGER REFERENCES unit_measure (id) not NULL, -- Unidad de venta (ej: PALETA)
    batching BOOLEAN DEFAULT FALSE, -- Indica si el producto maneja lotes
    serial_processing BOOLEAN DEFAULT FALSE, -- Indica si el producto maneja números de serie
    amount_of_content DECIMAL(10, 2), -- Cantidad por unidad
    pallet_load_weight DECIMAL(10, 2), -- Peso en kg por paleta
    box_weight DECIMAL(10, 2), -- Peso en kg por caja
    mt2_pallet DECIMAL(10, 2), -- Metros cuadrados por paleta
    mt2_box DECIMAL(10, 2), -- Metros cuadrados por caja
    currency_id INTEGER REFERENCES currency (id), -- FK a moneda (BS/USD)
    created_at DATE DEFAULT CURRENT_DATE, -- Fecha de creación del producto
    status_id INTEGER REFERENCES status (id) DEFAULT 1 -- Estado del producto (habilitado/deshabilitado)

);

-- Trigger para generar código de producto automáticamente
CREATE OR REPLACE FUNCTION generar_codigo_producto(
    p_categoria VARCHAR(4),    -- CEPI o CEPA
    p_calidad VARCHAR(1),      -- 1, 2 o 3
    p_secuencia INTEGER        -- Número secuencial
) RETURNS VARCHAR(20) AS $$
BEGIN
    -- Concatena: categoría + calidad + número secuencial con padding de ceros
    RETURN p_categoria || p_calidad || LPAD(p_secuencia::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Trigger para generar código de producto automáticamente
CREATE OR REPLACE FUNCTION trigger_generar_codigo_producto()
RETURNS TRIGGER AS $$
DECLARE
    v_categoria_codigo VARCHAR(4);
    v_calidad_codigo VARCHAR(1);
    v_ultimo_numero INTEGER;
BEGIN
    -- Si ya se proporcionó un código, respetarlo
    IF NEW.code IS NOT NULL AND NEW.code != '' THEN
        -- Si se proporcionó código pero no número de secuencia, extraer el número del código
        IF NEW.numeric_seq IS NULL THEN
            NEW.numeric_seq := SUBSTRING(NEW.code FROM 6)::INTEGER;
        END IF;
        RETURN NEW;
    END IF;

    -- Obtener el código de categoría
    SELECT code INTO v_categoria_codigo
    FROM category
    WHERE id = NEW.category_id;

    -- Obtener el código de calidad
    SELECT code INTO v_calidad_codigo
    FROM    quality
    WHERE id = NEW.quality_id;

    -- Si no se proporcionó número de secuencia, obtener el último número para esta categoría y calidad
    IF NEW.numeric_seq IS NULL THEN
        SELECT COALESCE(MAX(numeric_seq), 0) INTO v_ultimo_numero
        FROM products
        WHERE category_id = NEW.category_id
        AND quality_id = NEW.quality_id;

        -- Incrementar el número de secuencia
        v_ultimo_numero := v_ultimo_numero + 1;
        
        -- Asignar el nuevo número de secuencia
        NEW.numeric_seq := v_ultimo_numero;
    ELSE
        -- Usar el número de secuencia proporcionado
        v_ultimo_numero := NEW.numeric_seq;
    END IF;

    -- Generar y asignar el código de producto
    NEW.code := generar_codigo_producto(v_categoria_codigo, v_calidad_codigo, v_ultimo_numero);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER before_insert_productos
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION trigger_generar_codigo_producto();

-- Datos iniciales para las tablas
-- Categorías principales
INSERT INTO
    category (code, name, description)
VALUES 
    ('DAMA', 'Ropa de dama', 'Cerámicas para uso en pisos'),
    ('CABALLERO', 'Ropa de caballero', 'Cerámicas para uso en paredes'),
    ('NIÑO', 'Ropa de niño', 'Cerámicas para uso en pisos comerciales'),
    ('NIÑA', 'Ropa de niña', 'Cerámicas para uso en paredes comerciales');

-- Subcategorías para DAMA
INSERT INTO category (code, name, description, category_id)
VALUES
    ('DAMA-INT', 'Dama Íntima', 'Ropa íntima para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-JEA', 'Dama Jeans', 'Jeans para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-BLU', 'Dama Blusas', 'Blusas para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-VES', 'Dama Vestidos', 'Vestidos para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-CAM', 'Dama Camisas', 'Camisas para dama', (SELECT id FROM category WHERE code = 'DAMA'));
    

-- Subcategorías para CABALLERO
INSERT INTO category (code, name, description, category_id)
VALUES
    ('CAB-INT', 'Caballero Íntima', 'Ropa íntima para caballero', (SELECT id FROM category WHERE code = 'CABALLERO')),
    ('CAB-JEA', 'Caballero Jeans', 'Jeans para caballero', (SELECT id FROM category WHERE code = 'CABALLERO')),
    ('CAB-CAM', 'Caballero Camisas', 'Camisas para caballero', (SELECT id FROM category WHERE code = 'CABALLERO')),
    ('CAB-FRA', 'Caballero Franelas', 'Franelas para caballero', (SELECT id FROM category WHERE code = 'CABALLERO'));

-- Subcategorías para NIÑO
INSERT INTO category (code, name, description, category_id)
VALUES
    ('NINO-INT', 'Niño Íntima', 'Ropa íntima para niño', (SELECT id FROM category WHERE code = 'NIÑO')),
    ('NINO-JEA', 'Niño Jeans', 'Jeans para niño', (SELECT id FROM category WHERE code = 'NIÑO')),
    ('NINO-CAM', 'Niño Camisas', 'Camisas para niño', (SELECT id FROM category WHERE code = 'NIÑO')),
    ('NINO-FRA', 'Niño Franelas', 'Franelas para niño', (SELECT id FROM category WHERE code = 'NIÑO'));

-- Subcategorías para NIÑA
INSERT INTO category (code, name, description, category_id)
VALUES
    ('NINA-INT', 'Niña Íntima', 'Ropa íntima para niña', (SELECT id FROM category WHERE code = 'NIÑA')),
    ('NINA-JEA', 'Niña Jeans', 'Jeans para niña', (SELECT id FROM category WHERE code = 'NIÑA')),
    ('NINA-BLU', 'Niña Blusas', 'Blusas para niña', (SELECT id FROM category WHERE code = 'NIÑA')),
    ('NINA-VES', 'Niña Vestidos', 'Vestidos para niña', (SELECT id FROM category WHERE code = 'NIÑA'));

INSERT INTO
    quality (code, name)
VALUES ('1', '1ERA'),
    ('2', '2DA'),
    ('3', '3ERA'),
    ('4', 'COMERCIAL');

INSERT INTO
    currency (code, name)
VALUES ('BS', 'Bolívares'),
    ('USD', 'Dólares Americanos');

-- Formatos para ropa (usando unidad de medida TALLA)
INSERT INTO formats (dimensions, description, unit_measure_id) VALUES
('XS', 'Talla Extra Pequeña', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('S',  'Talla Pequeña', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('M',  'Talla Mediana', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('L',  'Talla Grande', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('XL', 'Talla Extra Grande', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('XXL', 'Talla Doble Extra Grande', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('U',  'Talla Única', (SELECT id FROM unit_measure WHERE code = 'TALLA'));

INSERT INTO
    model (code, name)
VALUES 
    ('JEA', 'Jeans'),
    ('BLU', 'Blusa'),
    ('CAM', 'Camisa'),
    ('FRA', 'Franela'),
    ('VES', 'Vestido'),
    ('INT', 'Ropa Íntima'),
    ('CHA', 'Chaqueta'),
    ('PNT', 'Pantalón'),
    ('SHO', 'Short'),
    ('FAL', 'Falda'),
    ('SWE', 'Suéter'),
    ('TOP', 'Top'),
    ('CHAQ', 'Chaqueta'),
    ('MON', 'Mono'),
    ('CON', 'Conjunto'),
    ('POL', 'Polera'),
    ('CHALE', 'Chaleco'),
    ('BER', 'Bermuda'),
    ('CAL', 'Calza'),
    ('REM', 'Remera');

INSERT INTO make (name) VALUES 
('ADIDAS'),
('PUMA'),
('REEBOK'),
('LE COQ SPORTIF'),
('CONVERSE'),
('FILA'),
('NEW BALANCE'),
('ASICS'),
('HUSH PUPPIES'),
('CLARKS'),
('TIMBERLAND'),
('CAT FOOTWEAR'),
('DC SHOES'),
('VANS'),
('LEVIS'),
('NIKE'),
('ZARA'),
('H&M'),
('GUCCI'),
('TOMMY HILFIGER'),
('RALPH LAUREN'),
('CALVIN KLEIN'),
('UNDER ARMOUR'),
('GAP'),
('AMERICAN EAGLE'),
('OLD NAVY'),
('BERSHKA'),
('MANGO'),
('LACOSTE'),
('OSHKOSH'),
('BABY GAP');
-- Insertar productos de ejemplo para una tienda de ropa
INSERT INTO products (
    code,
    category_id,
    quality_id,
    numeric_seq,
    format_id,
    model_id,
    make_id,
    name,
    unit_measure_id,
    batching,
    serial_processing,
    amount_of_content,
    pallet_load_weight,
    box_weight,
    mt2_pallet,
    mt2_box,
    currency_id
)
VALUES
-- Camisa Dama S
('DAMA-CAM-001', (SELECT id FROM category WHERE code = 'DAMA-CAM'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'S'), (SELECT id FROM model WHERE code = 'CAM'), (SELECT id FROM make WHERE name = 'ZARA'),
 'Camisa Manga Larga Dama Talla S', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Pantalón Caballero M
('CAB-PNT-001', (SELECT id FROM category WHERE code = 'CAB-JEA'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'M'), (SELECT id FROM model WHERE code = 'PNT'), (SELECT id FROM make WHERE name = 'LEVIS'),
 'Pantalón Jeans Caballero Talla M', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Vestido Niña L
('NINA-VES-001', (SELECT id FROM category WHERE code = 'NINA-VES'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'L'), (SELECT id FROM model WHERE code = 'VES'), (SELECT id FROM make WHERE name = 'MANGO'),
 'Vestido Fiesta Niña Talla L', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Franela Niño XS
('NINO-FRA-001', (SELECT id FROM category WHERE code = 'NINO-FRA'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'XS'), (SELECT id FROM model WHERE code = 'FRA'), (SELECT id FROM make WHERE name = 'ADIDAS'),
 'Franela Deportiva Niño Talla XS', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Blusa Dama M
('DAMA-BLU-001', (SELECT id FROM category WHERE code = 'DAMA-BLU'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'M'), (SELECT id FROM model WHERE code = 'BLU'), (SELECT id FROM make WHERE name = 'H&M'),
 'Blusa Casual Dama Talla M', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD'));



-- SQL para crear la tabla partner_type
CREATE TABLE partner_type (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(64) NOT NULL,
    code CHAR(1)
);

-- SQL para crear la tabla asociado
CREATE TABLE partners (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(64) NOT NULL,
    ident VARCHAR(25),
    email VARCHAR(255),
    phone VARCHAR(100),
    address VARCHAR(255),
    partner_type INTEGER NOT NULL REFERENCES partner_type(id),
    status_id INTEGER NOT NULL DEFAULT 2 REFERENCES status(id)
);


CREATE TABLE state_flow (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL default 0,
    name VARCHAR(24) NOT NULL
);

CREATE TABLE product_image (
    id Serial PRIMARY key,
    product_id INTEGER NOT NULL REFERENCES products(id),
    img_url VARCHAR NOT NULL
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    firstname VARCHAR(64) NOT NULL,
    lastname VARCHAR(64),
    type VARCHAR(64) NOT NULL,
    idem VARCHAR(25) NOT NULL UNIQUE,
    phone VARCHAR(100),
    email VARCHAR(255),
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 0
    is_delete BOOLEAN NOT NULL DEFAULT FALSE
);


CREATE TABLE profile (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);


CREATE TABLE rate (
    id SERIAL PRIMARY KEY,
    currency_id INTEGER REFERENCES currency(id),
    _value NUMERIC(18, 3) NOT NULL DEFAULT 0,
    rate_date DATE NOT NULL,
    rate_value NUMERIC(10, 2) NOT NULL DEFAULT 0
);

CREATE TABLE user_groups (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    group_id INTEGER REFERENCES user_groups(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE auth_user (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    user_id INTEGER NOT NULL REFERENCES users(id),
    username VARCHAR(32) NOT NULL UNIQUE,
    profile_id INTEGER NOT NULL REFERENCES profile(id),
    group_id INTEGER REFERENCES user_groups(id),
    status_id INTEGER NOT NULL DEFAULT 2 REFERENCES status(id),
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.user_groups ADD COLUMN created_by INTEGER NOT NULL REFERENCES auth_user(id);
ALTER TABLE public.user_groups ADD COLUMN updated_by INTEGER NOT NULL REFERENCES auth_user(id);

CREATE TABLE credential (
    id SERIAL PRIMARY KEY,
    auth_user_id INTEGER NOT NULL REFERENCES auth_user(id),
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    update_at TIMESTAMP NOT NULL,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);


CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    is_active INTEGER NOT NULL DEFAULT 1,
    path_name VARCHAR(255) DEFAULT '#',
    icon VARCHAR(255),
    label VARCHAR(255)
);


CREATE TABLE profile_rol (
    id SERIAL PRIMARY KEY,
    profile_id INTEGER NOT NULL REFERENCES profile(id),
    rol_id INTEGER NOT NULL REFERENCES roles(id),
    permissing_level INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE permissions_level (
    id SERIAL PRIMARY KEY,
    rol_id INTEGER NOT NULL REFERENCES roles(id),
    permissions_id INTEGER NOT NULL REFERENCES permissions(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- groups

-- Grupo principal (compañía)
INSERT INTO user_groups (name, description) VALUES
('OmniInv Company', 'Grupo principal de la compañía para todos los usuarios');

-- Perfiles
INSERT INTO profile (name) VALUES
('Administrador'),
('Vendedor'),
('Almacenero'),
('Comprador'),
('Gerente');

-- Roles
INSERT INTO roles (name, description, is_active, path_name, icon, label) VALUES
('Admin', 'Acceso total al sistema', 1, '/admin', 'admin_panel_settings', 'Administrador'),
('Ventas', 'Gestión de ventas y clientes', 1, '/ventas', 'point_of_sale', 'Vendedor'),
('Almacén', 'Gestión de inventario y almacenes', 1, '/almacen', 'warehouse', 'Almacenero'),
('Compras', 'Gestión de compras y proveedores', 1, '/compras', 'shopping_cart', 'Comprador'),
('Gerencia', 'Acceso a reportes y estadísticas', 1, '/gerencia', 'insights', 'Gerente');

-- Permisos
INSERT INTO permissions (name) VALUES
('Ver productos'),
('Crear productos'),
('Editar productos'),
('Eliminar productos'),
('Ver inventario'),
('Actualizar inventario'),
('Ver órdenes de compra'),
('Crear órdenes de compra'),
('Ver órdenes de venta'),
('Crear órdenes de venta'),
('Ver reportes'),
('Gestionar usuarios'),
('Ver proveedores'),
('Crear proveedores'),
('Ver clientes'),
('Crear clientes');

-- Relación roles-permisos
-- Admin: todos los permisos
INSERT INTO permissions_level (rol_id, permissions_id) 
SELECT 1, id FROM permissions;

-- Ventas: productos, ventas, clientes
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(2, 1), (2, 2), (2, 3), (2, 9), (2, 10), (2, 15), (2, 16);

-- Almacén: productos, inventario
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(3, 1), (3, 5), (3, 6);

-- Compras: productos, compras, proveedores
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(4, 1), (4, 7), (4, 8), (4, 13), (4, 14);

-- Gerencia: ver productos, inventario, compras, ventas, reportes
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(5, 1), (5, 5), (5, 7), (5, 9), (5, 11);

-- Relación perfiles-roles
INSERT INTO profile_rol (profile_id, rol_id, permissing_level) VALUES
(1, 1, 10),
(2, 2, 5),
(3, 3, 5),
(4, 4, 5),
(5, 5, 8);

INSERT INTO state_flow (version, name) VALUES
(1, 'Pediente'),
(2, 'Facturado'),
(3, 'Despachado'),
(4, 'Completado');

INSERT into partner_type (name, code ) values ('Proveedor', 'P');

INSERT INTO partners (name, contact_name, phone, email, address, partner_type) VALUES
('American Textiles Inc.', 'Emily Johnson', '+1-212-555-1234', 'contact@americantextiles.com', '123 5th Ave, New York, NY', 1),
('Urban Style LLC', 'Michael Smith', '+1-305-555-5678', 'sales@urbanstyle.com', '456 Ocean Dr, Miami, FL', 1),
('Fashion Distribution USA', 'Sophia Williams', '+1-213-555-7890', 'info@fashiondistributionusa.com', '789 Sunset Blvd, Los Angeles, CA', 1),
('Express Apparel', 'Andrew Brown', '+1-312-555-2345', 'sales@expressapparel.com', '321 Michigan Ave, Chicago, IL', 1),
('US Garment Solutions', 'Patricia Davis', '+1-713-555-6789', 'contact@usgarments.com', '654 Main St, Houston, TX', 1);

INSERT INTO users (name, lastname, type, idem, phone, email) VALUES
('Juan', 'Pérez', 'Empleado', 'V-12345678', '0412-1234567', 'juan.perez@ceramicas.com'),
('María', 'González', 'Empleado', 'V-87654321', '0414-9876543', 'maria.gonzalez@ceramicas.com'),
('Carlos', 'López', 'Empleado', 'V-11223344', '0416-5555555', 'carlos.lopez@ceramicas.com'),
('Ana', 'Martínez', 'Empleado', 'V-44332211', '0212-7777777', 'ana.martinez@ceramicas.com'),
('Pedro', 'Ramírez', 'Empleado', 'V-99887766', '0424-1111111', 'pedro.ramirez@ceramicas.com');


-- Ejemplo de inserción de usuarios en auth_user y credenciales en credential

-- Insertar usuarios en auth_user
INSERT INTO auth_user (user_id, username, profCREATE TABLE status (
    id serial primary key,
    name varchar(32),
    version integer DEFAULT 0
);

INSERT INTO status (name) values ('Habilitado');
INSERT INTO status (name) values ('Deshabilitado');
INSERT INTO status (name) values ('Bloqueado');
INSERT INTO status (name) values ('Eliminado');


create table unit_measure (
	id serial primary key,
	name varchar(32) not null,
	code varchar(8) not null
);


INSERT INTO unit_measure (name, code) VALUES
('Caja', 'CAJA'),
('Paleta', 'PALETA'),
('Metros Cuadrados', 'M2'),
('Kilogramos', 'KG'),
('Unidad', 'UNI'),
('Talla', 'TALLA'),
('Centimetros', 'cm'),
('Bulto', 'BULTO'),
('Docena', 'DOCENA');


-- Tabla Categorias: Almacena las categorías pr incipales de productos
CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    code VARCHAR(32), -- CEPI (Cerámica Piso) o CEPA (Cerámica Pared)
    name VARCHAR(100), -- Nombre completo: 'CERAMICA PISO' o 'CERAMICA PARED'
    description VARCHAR(200), -- Descripción detallada de la categoría
    category_id INTEGER,
    status_id INTEGER REFERENCES status (id) DEFAULT 1
);

ALTER TABLE category
    ADD CONSTRAINT fk_category_status FOREIGN KEY (status_id) REFERENCES status (id);

ALTER TABLE category
    ADD CONSTRAINT fk_category_category FOREIGN KEY (category_id) REFERENCES category (id);

-- Tabla Calidades: Define los niveles de calidad de los productos
CREATE TABLE quality (
    id SERIAL PRIMARY KEY,
    code VARCHAR(1), -- 1, 2, 3 (Para formar parte del código del producto)
    name VARCHAR(50) -- 1ERA, 2DA, 3ERA (Nombre descriptivo de la calidad)
);

-- Tabla Monedas: Define las monedas disponibles para precios
CREATE TABLE currency (
    id SERIAL PRIMARY KEY, -- 1=BS, 2=USD
    code VARCHAR(3), -- BS, USD
    name VARCHAR(50) -- Bolívares, Dólares Americanos
);

-- Tabla Formatos: Dimensiones disponibles para los productos
CREATE TABLE formats (
    id SERIAL PRIMARY KEY,
    dimensions VARCHAR(20), -- 33x33, 25x40 (dimensiones en centímetros)
    description VARCHAR(100), -- Descripción detallada del formato
    unit_measure_id INTEGER REFERENCES unit_measure (id) -- FK a unidad de medida
);

-- Tabla Modelos: Diferentes modelos de productos
CREATE TABLE model (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20), -- Código único del modelo (ej: CAICO, MACIZO, etc.)
    name VARCHAR(100) -- Nombre descriptivo del modelo
);

-- Tabla Marcas: Marcas de los productos
CREATE TABLE make (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) -- Nombre de la marca (ej: CERAMICA VIZCAYA)
);

-- Tabla Productos: Tabla principal de productos
CREATE TABLE products (
    id serial primary key,
    code VARCHAR(20) not NULL unique, -- Formato: CEPI/CEPA + 1/2/3 + 0001
    category_id INTEGER REFERENCES category (id) not null, -- FK a categoría (CEPI/CEPA)
    quality_id INTEGER REFERENCES quality (id) not null, -- FK a calidad (1ERA/2DA/3ERA)
    numeric_seq INTEGER, -- Número secuencial (0001, 0002, etc.)
    format_id INTEGER REFERENCES formats (id), -- FK al formato (33x33, 25x40)
    model_id INTEGER REFERENCES model (id), -- FK al modelo
    make_id INTEGER REFERENCES make (id), -- FK a la marca
    name VARCHAR(200) not null unique, -- Nombre completo del producto
    unit_measure_id INTEGER REFERENCES unit_measure (id) not NULL, -- Unidad de venta (ej: PALETA)
    batching BOOLEAN DEFAULT FALSE, -- Indica si el producto maneja lotes
    serial_processing BOOLEAN DEFAULT FALSE, -- Indica si el producto maneja números de serie
    amount_of_content DECIMAL(10, 2), -- Cantidad por unidad
    pallet_load_weight DECIMAL(10, 2), -- Peso en kg por paleta
    box_weight DECIMAL(10, 2), -- Peso en kg por caja
    mt2_pallet DECIMAL(10, 2), -- Metros cuadrados por paleta
    mt2_box DECIMAL(10, 2), -- Metros cuadrados por caja
    currency_id INTEGER REFERENCES currency (id), -- FK a moneda (BS/USD)
    created_at DATE DEFAULT CURRENT_DATE, -- Fecha de creación del producto
    status_id INTEGER REFERENCES status (id) DEFAULT 1 -- Estado del producto (habilitado/deshabilitado)

);

-- Trigger para generar código de producto automáticamente
CREATE OR REPLACE FUNCTION generar_codigo_producto(
    p_categoria VARCHAR(4),    -- CEPI o CEPA
    p_calidad VARCHAR(1),      -- 1, 2 o 3
    p_secuencia INTEGER        -- Número secuencial
) RETURNS VARCHAR(20) AS $$
BEGIN
    -- Concatena: categoría + calidad + número secuencial con padding de ceros
    RETURN p_categoria || p_calidad || LPAD(p_secuencia::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Trigger para generar código de producto automáticamente
CREATE OR REPLACE FUNCTION trigger_generar_codigo_producto()
RETURNS TRIGGER AS $$
DECLARE
    v_categoria_codigo VARCHAR(4);
    v_calidad_codigo VARCHAR(1);
    v_ultimo_numero INTEGER;
BEGIN
    -- Si ya se proporcionó un código, respetarlo
    IF NEW.code IS NOT NULL AND NEW.code != '' THEN
        -- Si se proporcionó código pero no número de secuencia, extraer el número del código
        IF NEW.numeric_seq IS NULL THEN
            NEW.numeric_seq := SUBSTRING(NEW.code FROM 6)::INTEGER;
        END IF;
        RETURN NEW;
    END IF;

    -- Obtener el código de categoría
    SELECT code INTO v_categoria_codigo
    FROM category
    WHERE id = NEW.category_id;

    -- Obtener el código de calidad
    SELECT code INTO v_calidad_codigo
    FROM    quality
    WHERE id = NEW.quality_id;

    -- Si no se proporcionó número de secuencia, obtener el último número para esta categoría y calidad
    IF NEW.numeric_seq IS NULL THEN
        SELECT COALESCE(MAX(numeric_seq), 0) INTO v_ultimo_numero
        FROM products
        WHERE category_id = NEW.category_id
        AND quality_id = NEW.quality_id;

        -- Incrementar el número de secuencia
        v_ultimo_numero := v_ultimo_numero + 1;
        
        -- Asignar el nuevo número de secuencia
        NEW.numeric_seq := v_ultimo_numero;
    ELSE
        -- Usar el número de secuencia proporcionado
        v_ultimo_numero := NEW.numeric_seq;
    END IF;

    -- Generar y asignar el código de producto
    NEW.code := generar_codigo_producto(v_categoria_codigo, v_calidad_codigo, v_ultimo_numero);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER before_insert_productos
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION trigger_generar_codigo_producto();

-- Datos iniciales para las tablas
-- Categorías principales
INSERT INTO
    category (code, name, description)
VALUES 
    ('DAMA', 'Ropa de dama', 'Cerámicas para uso en pisos'),
    ('CABALLERO', 'Ropa de caballero', 'Cerámicas para uso en paredes'),
    ('NIÑO', 'Ropa de niño', 'Cerámicas para uso en pisos comerciales'),
    ('NIÑA', 'Ropa de niña', 'Cerámicas para uso en paredes comerciales');

-- Subcategorías para DAMA
INSERT INTO category (code, name, description, category_id)
VALUES
    ('DAMA-INT', 'Dama Íntima', 'Ropa íntima para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-JEA', 'Dama Jeans', 'Jeans para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-BLU', 'Dama Blusas', 'Blusas para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-VES', 'Dama Vestidos', 'Vestidos para dama', (SELECT id FROM category WHERE code = 'DAMA')),
    ('DAMA-CAM', 'Dama Camisas', 'Camisas para dama', (SELECT id FROM category WHERE code = 'DAMA'));
    

-- Subcategorías para CABALLERO
INSERT INTO category (code, name, description, category_id)
VALUES
    ('CAB-INT', 'Caballero Íntima', 'Ropa íntima para caballero', (SELECT id FROM category WHERE code = 'CABALLERO')),
    ('CAB-JEA', 'Caballero Jeans', 'Jeans para caballero', (SELECT id FROM category WHERE code = 'CABALLERO')),
    ('CAB-CAM', 'Caballero Camisas', 'Camisas para caballero', (SELECT id FROM category WHERE code = 'CABALLERO')),
    ('CAB-FRA', 'Caballero Franelas', 'Franelas para caballero', (SELECT id FROM category WHERE code = 'CABALLERO'));

-- Subcategorías para NIÑO
INSERT INTO category (code, name, description, category_id)
VALUES
    ('NINO-INT', 'Niño Íntima', 'Ropa íntima para niño', (SELECT id FROM category WHERE code = 'NIÑO')),
    ('NINO-JEA', 'Niño Jeans', 'Jeans para niño', (SELECT id FROM category WHERE code = 'NIÑO')),
    ('NINO-CAM', 'Niño Camisas', 'Camisas para niño', (SELECT id FROM category WHERE code = 'NIÑO')),
    ('NINO-FRA', 'Niño Franelas', 'Franelas para niño', (SELECT id FROM category WHERE code = 'NIÑO'));

-- Subcategorías para NIÑA
INSERT INTO category (code, name, description, category_id)
VALUES
    ('NINA-INT', 'Niña Íntima', 'Ropa íntima para niña', (SELECT id FROM category WHERE code = 'NIÑA')),
    ('NINA-JEA', 'Niña Jeans', 'Jeans para niña', (SELECT id FROM category WHERE code = 'NIÑA')),
    ('NINA-BLU', 'Niña Blusas', 'Blusas para niña', (SELECT id FROM category WHERE code = 'NIÑA')),
    ('NINA-VES', 'Niña Vestidos', 'Vestidos para niña', (SELECT id FROM category WHERE code = 'NIÑA'));

INSERT INTO
    quality (code, name)
VALUES ('1', '1ERA'),
    ('2', '2DA'),
    ('3', '3ERA'),
    ('4', 'COMERCIAL');

INSERT INTO
    currency (code, name)
VALUES ('BS', 'Bolívares'),
    ('USD', 'Dólares Americanos');

-- Formatos para ropa (usando unidad de medida TALLA)
INSERT INTO formats (dimensions, description, unit_measure_id) VALUES
('XS', 'Talla Extra Pequeña', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('S',  'Talla Pequeña', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('M',  'Talla Mediana', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('L',  'Talla Grande', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('XL', 'Talla Extra Grande', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('XXL', 'Talla Doble Extra Grande', (SELECT id FROM unit_measure WHERE code = 'TALLA')),
('U',  'Talla Única', (SELECT id FROM unit_measure WHERE code = 'TALLA'));

INSERT INTO
    model (code, name)
VALUES 
    ('JEA', 'Jeans'),
    ('BLU', 'Blusa'),
    ('CAM', 'Camisa'),
    ('FRA', 'Franela'),
    ('VES', 'Vestido'),
    ('INT', 'Ropa Íntima'),
    ('CHA', 'Chaqueta'),
    ('PNT', 'Pantalón'),
    ('SHO', 'Short'),
    ('FAL', 'Falda'),
    ('SWE', 'Suéter'),
    ('TOP', 'Top'),
    ('CHAQ', 'Chaqueta'),
    ('MON', 'Mono'),
    ('CON', 'Conjunto'),
    ('POL', 'Polera'),
    ('CHALE', 'Chaleco'),
    ('BER', 'Bermuda'),
    ('CAL', 'Calza'),
    ('REM', 'Remera');

INSERT INTO make (name) VALUES 
('ADIDAS'),
('PUMA'),
('REEBOK'),
('LE COQ SPORTIF'),
('CONVERSE'),
('FILA'),
('NEW BALANCE'),
('ASICS'),
('HUSH PUPPIES'),
('CLARKS'),
('TIMBERLAND'),
('CAT FOOTWEAR'),
('DC SHOES'),
('VANS'),
('LEVIS'),
('NIKE'),
('ZARA'),
('H&M'),
('GUCCI'),
('TOMMY HILFIGER'),
('RALPH LAUREN'),
('CALVIN KLEIN'),
('UNDER ARMOUR'),
('GAP'),
('AMERICAN EAGLE'),
('OLD NAVY'),
('BERSHKA'),
('MANGO'),
('LACOSTE'),
('OSHKOSH'),
('BABY GAP');
-- Insertar productos de ejemplo para una tienda de ropa
INSERT INTO products (
    code,
    category_id,
    quality_id,
    numeric_seq,
    format_id,
    model_id,
    make_id,
    name,
    unit_measure_id,
    batching,
    serial_processing,
    amount_of_content,
    pallet_load_weight,
    box_weight,
    mt2_pallet,
    mt2_box,
    currency_id
)
VALUES
-- Camisa Dama S
('DAMA-CAM-001', (SELECT id FROM category WHERE code = 'DAMA-CAM'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'S'), (SELECT id FROM model WHERE code = 'CAM'), (SELECT id FROM make WHERE name = 'ZARA'),
 'Camisa Manga Larga Dama Talla S', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Pantalón Caballero M
('CAB-PNT-001', (SELECT id FROM category WHERE code = 'CAB-JEA'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'M'), (SELECT id FROM model WHERE code = 'PNT'), (SELECT id FROM make WHERE name = 'LEVIS'),
 'Pantalón Jeans Caballero Talla M', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Vestido Niña L
('NINA-VES-001', (SELECT id FROM category WHERE code = 'NINA-VES'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'L'), (SELECT id FROM model WHERE code = 'VES'), (SELECT id FROM make WHERE name = 'MANGO'),
 'Vestido Fiesta Niña Talla L', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Franela Niño XS
('NINO-FRA-001', (SELECT id FROM category WHERE code = 'NINO-FRA'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'XS'), (SELECT id FROM model WHERE code = 'FRA'), (SELECT id FROM make WHERE name = 'ADIDAS'),
 'Franela Deportiva Niño Talla XS', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD')),
-- Blusa Dama M
('DAMA-BLU-001', (SELECT id FROM category WHERE code = 'DAMA-BLU'), (SELECT id FROM quality WHERE code = '1'), 1,
 (SELECT id FROM formats WHERE dimensions = 'M'), (SELECT id FROM model WHERE code = 'BLU'), (SELECT id FROM make WHERE name = 'H&M'),
 'Blusa Casual Dama Talla M', (SELECT id FROM unit_measure WHERE code = 'TALLA'), FALSE, FALSE, 1, NULL, NULL, NULL, NULL, (SELECT id FROM currency WHERE code = 'USD'));



-- SQL para crear la tabla partner_type
CREATE TABLE partner_type (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(64) NOT NULL,
    code CHAR(1)
);

-- SQL para crear la tabla asociado
CREATE TABLE partners (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(64) NOT NULL,
    ident VARCHAR(25),
    email VARCHAR(255),
    phone VARCHAR(100),
    address VARCHAR(255),
    partner_type INTEGER NOT NULL REFERENCES partner_type(id),
    status_id INTEGER NOT NULL DEFAULT 2 REFERENCES status(id)
);


CREATE TABLE state_flow (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL default 0,
    name VARCHAR(24) NOT NULL
);

CREATE TABLE product_image (
    id Serial PRIMARY key,
    product_id INTEGER NOT NULL REFERENCES products(id),
    img_url VARCHAR NOT NULL
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    firstname VARCHAR(64) NOT NULL,
    lastname VARCHAR(64),
    type VARCHAR(64) NOT NULL,
    idem VARCHAR(25) NOT NULL UNIQUE,
    phone VARCHAR(100),
    email VARCHAR(255),
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 0
    is_delete BOOLEAN NOT NULL DEFAULT FALSE
);


CREATE TABLE profile (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);


CREATE TABLE rate (
    id SERIAL PRIMARY KEY,
    currency_id INTEGER REFERENCES currency(id),
    _value NUMERIC(18, 3) NOT NULL DEFAULT 0,
    rate_date DATE NOT NULL,
    rate_value NUMERIC(10, 2) NOT NULL DEFAULT 0
);

CREATE TABLE user_groups (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    group_id INTEGER REFERENCES user_groups(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE auth_user (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    user_id INTEGER NOT NULL REFERENCES users(id),
    username VARCHAR(32) NOT NULL UNIQUE,
    profile_id INTEGER NOT NULL REFERENCES profile(id),
    group_id INTEGER REFERENCES user_groups(id),
    status_id INTEGER NOT NULL DEFAULT 2 REFERENCES status(id),
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.user_groups ADD COLUMN created_by INTEGER NOT NULL REFERENCES auth_user(id);
ALTER TABLE public.user_groups ADD COLUMN updated_by INTEGER NOT NULL REFERENCES auth_user(id);

CREATE TABLE credential (
    id SERIAL PRIMARY KEY,
    auth_user_id INTEGER NOT NULL REFERENCES auth_user(id),
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    update_at TIMESTAMP NOT NULL,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);


CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    is_active INTEGER NOT NULL DEFAULT 1,
    path_name VARCHAR(255) DEFAULT '#',
    icon VARCHAR(255),
    label VARCHAR(255)
);


CREATE TABLE profile_rol (
    id SERIAL PRIMARY KEY,
    profile_id INTEGER NOT NULL REFERENCES profile(id),
    rol_id INTEGER NOT NULL REFERENCES roles(id),
    permissing_level INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE permissions_level (
    id SERIAL PRIMARY KEY,
    rol_id INTEGER NOT NULL REFERENCES roles(id),
    permissions_id INTEGER NOT NULL REFERENCES permissions(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- groups

-- Grupo principal (compañía)
INSERT INTO user_groups (name, description) VALUES
('OmniInv Company', 'Grupo principal de la compañía para todos los usuarios');

-- Perfiles
INSERT INTO profile (name) VALUES
('Administrador'),
('Vendedor'),
('Almacenero'),
('Comprador'),
('Gerente');

-- Roles
INSERT INTO roles (name, description, is_active, path_name, icon, label) VALUES
('Admin', 'Acceso total al sistema', 1, '/admin', 'admin_panel_settings', 'Administrador'),
('Ventas', 'Gestión de ventas y clientes', 1, '/ventas', 'point_of_sale', 'Vendedor'),
('Almacén', 'Gestión de inventario y almacenes', 1, '/almacen', 'warehouse', 'Almacenero'),
('Compras', 'Gestión de compras y proveedores', 1, '/compras', 'shopping_cart', 'Comprador'),
('Gerencia', 'Acceso a reportes y estadísticas', 1, '/gerencia', 'insights', 'Gerente');

-- Permisos
INSERT INTO permissions (name) VALUES
('Ver productos'),
('Crear productos'),
('Editar productos'),
('Eliminar productos'),
('Ver inventario'),
('Actualizar inventario'),
('Ver órdenes de compra'),
('Crear órdenes de compra'),
('Ver órdenes de venta'),
('Crear órdenes de venta'),
('Ver reportes'),
('Gestionar usuarios'),
('Ver proveedores'),
('Crear proveedores'),
('Ver clientes'),
('Crear clientes');

-- Relación roles-permisos
-- Admin: todos los permisos
INSERT INTO permissions_level (rol_id, permissions_id) 
SELECT 1, id FROM permissions;

-- Ventas: productos, ventas, clientes
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(2, 1), (2, 2), (2, 3), (2, 9), (2, 10), (2, 15), (2, 16);

-- Almacén: productos, inventario
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(3, 1), (3, 5), (3, 6);

-- Compras: productos, compras, proveedores
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(4, 1), (4, 7), (4, 8), (4, 13), (4, 14);

-- Gerencia: ver productos, inventario, compras, ventas, reportes
INSERT INTO permissions_level (rol_id, permissions_id) VALUES
(5, 1), (5, 5), (5, 7), (5, 9), (5, 11);

-- Relación perfiles-roles
INSERT INTO profile_rol (profile_id, rol_id, permissing_level) VALUES
(1, 1, 10),
(2, 2, 5),
(3, 3, 5),
(4, 4, 5),
(5, 5, 8);

INSERT INTO state_flow (version, name) VALUES
(1, 'Pediente'),
(2, 'Facturado'),
(3, 'Despachado'),
(4, 'Completado');

INSERT into partner_type (name, code ) values ('Proveedor', 'P');

INSERT INTO partners (name, contact_name, phone, email, address, partner_type) VALUES
('American Textiles Inc.', 'Emily Johnson', '+1-212-555-1234', 'contact@americantextiles.com', '123 5th Ave, New York, NY', 1),
('Urban Style LLC', 'Michael Smith', '+1-305-555-5678', 'sales@urbanstyle.com', '456 Ocean Dr, Miami, FL', 1),
('Fashion Distribution USA', 'Sophia Williams', '+1-213-555-7890', 'info@fashiondistributionusa.com', '789 Sunset Blvd, Los Angeles, CA', 1),
('Express Apparel', 'Andrew Brown', '+1-312-555-2345', 'sales@expressapparel.com', '321 Michigan Ave, Chicago, IL', 1),
('US Garment Solutions', 'Patricia Davis', '+1-713-555-6789', 'contact@usgarments.com', '654 Main St, Houston, TX', 1);

INSERT INTO users (name, lastname, type, idem, phone, email) VALUES
('Juan', 'Pérez', 'Empleado', 'V-12345678', '0412-1234567', 'juan.perez@ceramicas.com'),
('María', 'González', 'Empleado', 'V-87654321', '0414-9876543', 'maria.gonzalez@ceramicas.com'),
('Carlos', 'López', 'Empleado', 'V-11223344', '0416-5555555', 'carlos.lopez@ceramicas.com'),
('Ana', 'Martínez', 'Empleado', 'V-44332211', '0212-7777777', 'ana.martinez@ceramicas.com'),
('Pedro', 'Ramírez', 'Empleado', 'V-99887766', '0424-1111111', 'pedro.ramirez@ceramicas.com');


-- Ejemplo de inserción de usuarios en auth_user y credenciales en credential

-- Insertar usuarios en auth_user
INSERT INTO auth_user (user_id, username, profile_id, status_id, group_id)
VALUES
((SELECT id FROM users WHERE idem = 'V-12345678'), 'juan.perez', (SELECT id FROM profile WHERE name = 'Administrador'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-87654321'), 'maria.gonzalez', (SELECT id FROM profile WHERE name = 'Vendedor'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-11223344'), 'carlos.lopez', (SELECT id FROM profile WHERE name = 'Almacenero'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-44332211'), 'ana.martinez', (SELECT id FROM profile WHERE name = 'Comprador'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-99887766'), 'pedro.ramirez', (SELECT id FROM profile WHERE name = 'Gerente'), 1, 1);

-- Insertar contraseñas en credential (asumiendo que los auth_user ya fueron insertados)
INSERT INTO credential (auth_user_id, password, created_at, update_at)
SELECT id, '$2b$12$nZf.W676IERk5e15sNQQ.Oje39rHByNMMmDd5oydJk5reRjpNUj16', NOW(), NOW()
FROM auth_user
WHERE username IN ('juan.perez', 'maria.gonzalez', 'carlos.lopez', 'ana.martinez', 'pedro.ramirez');


-- Tabla de Órdenes de Compra (Encabezado)
CREATE TABLE purchase_orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    partner_id INTEGER NOT NULL REFERENCES partners(id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_date DATE,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id),
    state_flow INTEGER NOT NULL DEFAULT 3 REFERENCES state_flow(id), -- Pendiente por defecto
    rate_id INTEGER references rate(id),
    total_amount DECIMAL(18, 2),
    notes TEXT
);

--INSERT INTO purchase_orders (order_number, partner_id, delivery_date, created_by_user_id, total_amount) VALUES
--('OC-2025-001', (SELECT id FROM partners WHERE name = 'Ladrillos del Sur CA'), '2025-04-20', (SELECT id FROM users WHERE idem = 'V-44332211'), 5600.00),
--('OC-2025-002', (SELECT id FROM partners WHERE name = 'Insumos Cerámicos SA'), '2025-04-25', (SELECT id FROM users WHERE idem = 'V-44332211'), 1500.50);

-- Tabla de Detalles de Órdenes de Compra
CREATE TABLE purchase_order_details (
    id SERIAL PRIMARY KEY,
    purchase_order_id INTEGER NOT NULL REFERENCES purchase_orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL
);

--INSERT INTO purchase_order_details (purchase_order_id, product_id, quantity, unit_price, subtotal) VALUES
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-001'), (SELECT id FROM products WHERE id = 50), 5000, 0.80, 4000.00),
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-001'), (SELECT id FROM products WHERE id = 60), 20, 80.00, 1600.00),
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-002'), (SELECT id FROM products WHERE id = 70), 200, 5.00, 1000.00),
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-002'), (SELECT id FROM products WHERE id = 80), 50, 10.01, 500.50);


-- Tabla de Almacenes (Warehouses)
CREATE TABLE warehouses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE,
    address TEXT,
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO warehouses (name, code, address) VALUES
('Almacén Principal', 'ALM-PRI', 'Zona Industrial Central, Galpón 1'),
('Almacén de Materia Prima', 'ALM-MAT', 'Carretera Nacional, Sector La Mata'),
('Warehouse New York', 'ALM-NY', '123 5th Ave, New York, NY, USA'),
('Warehouse Miami', 'ALM-MIA', '456 Ocean Dr, Miami, FL, USA');


-- Tabla de Inventario (Stock)
CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    stock_quantity DECIMAL(18, 2) NOT NULL DEFAULT 0,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (warehouse_id, product_id)
);

INSERT INTO inventory (warehouse_id, product_id, stock_quantity) VALUES
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 1), 1500.00),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 2), 50.00),
((SELECT id FROM warehouses WHERE code = 'ALM-NY'), (SELECT id FROM products WHERE id = 3), 10000.00),
((SELECT id FROM warehouses WHERE code = 'ALM-MIA'), (SELECT id FROM products WHERE id = 4), 200.00);

-- Tabla de Movimientos de Inventario (ejemplos de entradas por compras)
CREATE TABLE inventory_movements (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    movement_type VARCHAR(50) NOT NULL CHECK (movement_type IN ('ENTRADA', 'SALIDA')),
    quantity DECIMAL(10, 2) NOT NULL,
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_document VARCHAR(255), -- Ej: Número de Orden de Compra, Número de Despacho
    unit_measure_id INTEGER NOT NULL REFERENCES unit_measure(id),
    notes TEXT
);

INSERT INTO inventory_movements (warehouse_id, product_id, movement_type, quantity, source_document, unit_measure_id) VALUES
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 1), 'ENTRADA', 5000.00, 'OC-2025-001', 2),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 3), 'ENTRADA', 20.00, 'OC-2025-001', 2),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 2), 'ENTRADA', 200.00, 'OC-2025-002', 2),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 5), 'ENTRADA', 50.00, 'OC-2025-002', 2);


-- Tabla de Órdenes de Despacho (Salida de Almacén) - Para el módulo de logística
CREATE TABLE dispatch_orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    dispatch_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id),
    status_id INTEGER NOT NULL DEFAULT 3 REFERENCES status(id), -- Pendiente por defecto
    notes TEXT
);

-- Tabla de Detalles de Órdenes de Despacho
CREATE TABLE dispatch_order_details (
    id SERIAL PRIMARY KEY,
    dispatch_order_id INTEGER NOT NULL REFERENCES dispatch_orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity DECIMAL(10, 2) NOT NULL
);

-- Tabla de Rutas de Despacho (opcional, para logística)
CREATE TABLE dispatch_routes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

-- Tabla de Asignación de Despachos a Rutas (opcional, para logística)
CREATE TABLE dispatch_route_assignments (
    id SERIAL PRIMARY KEY,
    dispatch_order_id INTEGER NOT NULL REFERENCES dispatch_orders(id),
    route_id INTEGER REFERENCES dispatch_routes(id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE error_logs (
    id VARCHAR PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    code VARCHAR NOT NULL,
    message VARCHAR NOT NULL,
    request VARCHAR NOT NULL,
    db VARCHAR
);

-- Tabla para el concepto de Merma
CREATE TABLE shrinkage_reasons (
    id SERIAL PRIMARY KEY,
    reason_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT
);

-- Tabla para relacionar los movimientos de inventario con las mermas
CREATE TABLE inventory_shrinkage (
    id SERIAL PRIMARY KEY,
    inventory_movement_id integer NOT NULL,
    shrinkage_reason_id integer NOT NULL,
    quantity_lost integer NOT NULL,
    price numeric(18,2),
    loss_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rate_id integer not null,
    notes TEXT,
    FOREIGN KEY (inventory_movement_id) REFERENCES inventory_movements(id),
    FOREIGN KEY (shrinkage_reason_id) REFERENCES shrinkage_reasons(id),
    foreign key (rate_id) references rate(id)  
);

-- Posibles valores para la tabla shrinkage_reasons
INSERT INTO shrinkage_reasons (reason_name, description) VALUES
('Roto', 'Producto dañado o quebrado durante el manejo o almacenamiento.'),
('Deterioro', 'Producto que se ha deteriorado debido a condiciones ambientales o almacenamiento inadecuado.'),
('Hurto', 'Sustracción del producto sin autorización.'),
('Error de Conteo', 'Discrepancia entre el conteo físico y el registro del sistema.'),
('Pérdida', 'Producto extraviado y no encontrado.'),
('Exhibición', 'Producto utilizado para fines de marketing o prueba.'),
('Ajuste de Inventario', 'Ajuste realizado para corregir discrepancias no identificadas.');
ile_id, status_id, group_id)
VALUES
((SELECT id FROM users WHERE idem = 'V-12345678'), 'juan.perez', (SELECT id FROM profile WHERE name = 'Administrador'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-87654321'), 'maria.gonzalez', (SELECT id FROM profile WHERE name = 'Vendedor'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-11223344'), 'carlos.lopez', (SELECT id FROM profile WHERE name = 'Almacenero'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-44332211'), 'ana.martinez', (SELECT id FROM profile WHERE name = 'Comprador'), 1, 1),
((SELECT id FROM users WHERE idem = 'V-99887766'), 'pedro.ramirez', (SELECT id FROM profile WHERE name = 'Gerente'), 1, 1);

-- Insertar contraseñas en credential (asumiendo que los auth_user ya fueron insertados)
INSERT INTO credential (auth_user_id, password, created_at, update_at)
SELECT id, '$2b$12$nZf.W676IERk5e15sNQQ.Oje39rHByNMMmDd5oydJk5reRjpNUj16', NOW(), NOW()
FROM auth_user
WHERE username IN ('juan.perez', 'maria.gonzalez', 'carlos.lopez', 'ana.martinez', 'pedro.ramirez');


-- Tabla de Órdenes de Compra (Encabezado)
CREATE TABLE purchase_orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    partner_id INTEGER NOT NULL REFERENCES partners(id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_date DATE,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id),
    state_flow INTEGER NOT NULL DEFAULT 3 REFERENCES state_flow(id), -- Pendiente por defecto
    rate_id INTEGER references rate(id),
    total_amount DECIMAL(18, 2),
    notes TEXT
);

--INSERT INTO purchase_orders (order_number, partner_id, delivery_date, created_by_user_id, total_amount) VALUES
--('OC-2025-001', (SELECT id FROM partners WHERE name = 'Ladrillos del Sur CA'), '2025-04-20', (SELECT id FROM users WHERE idem = 'V-44332211'), 5600.00),
--('OC-2025-002', (SELECT id FROM partners WHERE name = 'Insumos Cerámicos SA'), '2025-04-25', (SELECT id FROM users WHERE idem = 'V-44332211'), 1500.50);

-- Tabla de Detalles de Órdenes de Compra
CREATE TABLE purchase_order_details (
    id SERIAL PRIMARY KEY,
    purchase_order_id INTEGER NOT NULL REFERENCES purchase_orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL
);

--INSERT INTO purchase_order_details (purchase_order_id, product_id, quantity, unit_price, subtotal) VALUES
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-001'), (SELECT id FROM products WHERE id = 50), 5000, 0.80, 4000.00),
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-001'), (SELECT id FROM products WHERE id = 60), 20, 80.00, 1600.00),
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-002'), (SELECT id FROM products WHERE id = 70), 200, 5.00, 1000.00),
--((SELECT id FROM purchase_orders WHERE order_number = 'OC-2025-002'), (SELECT id FROM products WHERE id = 80), 50, 10.01, 500.50);


-- Tabla de Almacenes (Warehouses)
CREATE TABLE warehouses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE,
    address TEXT,
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO warehouses (name, code, address) VALUES
('Almacén Principal', 'ALM-PRI', 'Zona Industrial Central, Galpón 1'),
('Almacén de Materia Prima', 'ALM-MAT', 'Carretera Nacional, Sector La Mata'),
('Warehouse New York', 'ALM-NY', '123 5th Ave, New York, NY, USA'),
('Warehouse Miami', 'ALM-MIA', '456 Ocean Dr, Miami, FL, USA');


-- Tabla de Inventario (Stock)
CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    stock_quantity DECIMAL(18, 2) NOT NULL DEFAULT 0,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (warehouse_id, product_id)
);

INSERT INTO inventory (warehouse_id, product_id, stock_quantity) VALUES
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 1), 1500.00),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 2), 50.00),
((SELECT id FROM warehouses WHERE code = 'ALM-NY'), (SELECT id FROM products WHERE id = 3), 10000.00),
((SELECT id FROM warehouses WHERE code = 'ALM-MIA'), (SELECT id FROM products WHERE id = 4), 200.00);

-- Tabla de Movimientos de Inventario (ejemplos de entradas por compras)
CREATE TABLE inventory_movements (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    movement_type VARCHAR(50) NOT NULL CHECK (movement_type IN ('ENTRADA', 'SALIDA')),
    quantity DECIMAL(10, 2) NOT NULL,
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_document VARCHAR(255), -- Ej: Número de Orden de Compra, Número de Despacho
    unit_measure_id INTEGER NOT NULL REFERENCES unit_measure(id),
    notes TEXT
);

INSERT INTO inventory_movements (warehouse_id, product_id, movement_type, quantity, source_document, unit_measure_id) VALUES
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 1), 'ENTRADA', 5000.00, 'OC-2025-001', 2),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 3), 'ENTRADA', 20.00, 'OC-2025-001', 2),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 2), 'ENTRADA', 200.00, 'OC-2025-002', 2),
((SELECT id FROM warehouses WHERE code = 'ALM-PRI'), (SELECT id FROM products WHERE id = 5), 'ENTRADA', 50.00, 'OC-2025-002', 2);


-- Tabla de Órdenes de Despacho (Salida de Almacén) - Para el módulo de logística
CREATE TABLE dispatch_orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    dispatch_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id),
    status_id INTEGER NOT NULL DEFAULT 3 REFERENCES status(id), -- Pendiente por defecto
    notes TEXT
);

-- Tabla de Detalles de Órdenes de Despacho
CREATE TABLE dispatch_order_details (
    id SERIAL PRIMARY KEY,
    dispatch_order_id INTEGER NOT NULL REFERENCES dispatch_orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity DECIMAL(10, 2) NOT NULL
);

-- Tabla de Rutas de Despacho (opcional, para logística)
CREATE TABLE dispatch_routes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

-- Tabla de Asignación de Despachos a Rutas (opcional, para logística)
CREATE TABLE dispatch_route_assignments (
    id SERIAL PRIMARY KEY,
    dispatch_order_id INTEGER NOT NULL REFERENCES dispatch_orders(id),
    route_id INTEGER REFERENCES dispatch_routes(id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE error_logs (
    id VARCHAR PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    code VARCHAR NOT NULL,
    message VARCHAR NOT NULL,
    request VARCHAR NOT NULL,
    db VARCHAR
);

-- Tabla para el concepto de Merma
CREATE TABLE shrinkage_reasons (
    id SERIAL PRIMARY KEY,
    reason_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT
);

-- Tabla para relacionar los movimientos de inventario con las mermas
CREATE TABLE inventory_shrinkage (
    id SERIAL PRIMARY KEY,
    inventory_movement_id integer NOT NULL,
    shrinkage_reason_id integer NOT NULL,
    quantity_lost integer NOT NULL,
    price numeric(18,2),
    loss_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rate_id integer not null,
    notes TEXT,
    FOREIGN KEY (inventory_movement_id) REFERENCES inventory_movements(id),
    FOREIGN KEY (shrinkage_reason_id) REFERENCES shrinkage_reasons(id),
    foreign key (rate_id) references rate(id)  
);

-- Posibles valores para la tabla shrinkage_reasons
INSERT INTO shrinkage_reasons (reason_name, description) VALUES
('Roto', 'Producto dañado o quebrado durante el manejo o almacenamiento.'),
('Deterioro', 'Producto que se ha deteriorado debido a condiciones ambientales o almacenamiento inadecuado.'),
('Hurto', 'Sustracción del producto sin autorización.'),
('Error de Conteo', 'Discrepancia entre el conteo físico y el registro del sistema.'),
('Pérdida', 'Producto extraviado y no encontrado.'),
('Exhibición', 'Producto utilizado para fines de marketing o prueba.'),
('Ajuste de Inventario', 'Ajuste realizado para corregir discrepancias no identificadas.');
