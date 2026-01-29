-- Cria os bancos adicionais para Rails (cache, queue, cable).
-- O banco vendi_production já é criado pelo POSTGRES_DB do container.
CREATE DATABASE vendi_production_cache OWNER vendi;
CREATE DATABASE vendi_production_queue OWNER vendi;
CREATE DATABASE vendi_production_cable OWNER vendi;
