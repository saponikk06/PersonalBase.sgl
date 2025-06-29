--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

-- Started on 2025-06-29 15:04:55

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 28704)
-- Name: course; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA course;


ALTER SCHEMA course OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 28708)
-- Name: finance; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA finance;


ALTER SCHEMA finance OWNER TO postgres;

--
-- TOC entry 10 (class 2615 OID 28706)
-- Name: habits; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA habits;


ALTER SCHEMA habits OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 28709)
-- Name: todo; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA todo;


ALTER SCHEMA todo OWNER TO postgres;

--
-- TOC entry 11 (class 2615 OID 28705)
-- Name: trips; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA trips;


ALTER SCHEMA trips OWNER TO postgres;

--
-- TOC entry 7 (class 2615 OID 28707)
-- Name: user; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "user";


ALTER SCHEMA "user" OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 27192)
-- Name: update_course_status(); Type: FUNCTION; Schema: course; Owner: postgres
--

CREATE FUNCTION course.update_course_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_status integer;
    all_completed boolean;
    any_started boolean;
BEGIN
    SELECT COUNT(*) = SUM(CASE WHEN completed_date IS NOT NULL THEN 1 ELSE 0 END)
    INTO all_completed
    FROM course.course_topics
    WHERE course_id = NEW.course_id;

    SELECT COUNT(*) > 0
    INTO any_started
    FROM course.course_topics
    WHERE course_id = NEW.course_id AND completed_date IS NOT NULL;

    IF all_completed THEN
        new_status := 3;
    ELSIF any_started THEN
        new_status := 2;
    ELSE
        new_status := 1;
    END IF;

    IF (SELECT status_id FROM course.courses WHERE course_id = NEW.course_id) != new_status THEN
        UPDATE course.courses
        SET status_id = new_status,
            updated_at = CURRENT_TIMESTAMP
        WHERE course_id = NEW.course_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION course.update_course_status() OWNER TO postgres;

--
-- TOC entry 5170 (class 0 OID 0)
-- Dependencies: 274
-- Name: FUNCTION update_course_status(); Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON FUNCTION course.update_course_status() IS 'Обновляет status_id в таблице courses на основе завершения тем в course_topics: ''Запланировано'' (нет тем), ''Завершено'' (все темы завершены), ''В процессе'' (иначе). Вызывается триггером course_topics_status_trigger после вставки или обновления completed_date.';


--
-- TOC entry 262 (class 1255 OID 27770)
-- Name: check_finance_amount(); Type: FUNCTION; Schema: finance; Owner: postgres
--

CREATE FUNCTION finance.check_finance_amount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    is_income boolean;
BEGIN
    SELECT ft.is_income INTO is_income
    FROM finance.finance_categories fc  -- Добавляем схему finance
    JOIN finance.finance_types ft ON fc.type_id = ft.type_id
    WHERE fc.category_id = NEW.category_id;

    IF is_income AND NEW.amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive for income category';
    ELSIF NOT is_income AND NEW.amount >= 0 THEN
        RAISE EXCEPTION 'Amount must be negative for expense category';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION finance.check_finance_amount() OWNER TO postgres;

--
-- TOC entry 5171 (class 0 OID 0)
-- Dependencies: 262
-- Name: FUNCTION check_finance_amount(); Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON FUNCTION finance.check_finance_amount() IS 'Проверяет корректность суммы в таблице finances: положительная для доходов (type.name = ''Доход''), отрицательная для расходов (type.name = ''Расход''). Вызывается триггером finances_amount_trigger перед вставкой или обновлением записи.';


--
-- TOC entry 261 (class 1255 OID 26924)
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at() OWNER TO postgres;

--
-- TOC entry 5172 (class 0 OID 0)
-- Dependencies: 261
-- Name: FUNCTION update_updated_at(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.update_updated_at() IS 'Обновляет поле updated_at на CURRENT_TIMESTAMP при изменении записи в таблицах users, finances, todos, courses и других. Вызывается триггерами updated_at_trigger перед обновлением записей.';


--
-- TOC entry 260 (class 1255 OID 26708)
-- Name: set_completed_date(); Type: FUNCTION; Schema: todo; Owner: postgres
--

CREATE FUNCTION todo.set_completed_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.is_completed = TRUE AND OLD.is_completed = FALSE THEN
        NEW.completed_date = CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION todo.set_completed_date() OWNER TO postgres;

--
-- TOC entry 5173 (class 0 OID 0)
-- Dependencies: 260
-- Name: FUNCTION set_completed_date(); Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON FUNCTION todo.set_completed_date() IS 'Устанавливает поле completed_date в таблице todos на текущую дату (CURRENT_DATE), если is_completed изменяется на TRUE. Вызывается триггером todos_completed_date_trigger перед обновлением записи.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 252 (class 1259 OID 27694)
-- Name: course_statuses; Type: TABLE; Schema: course; Owner: postgres
--

CREATE TABLE course.course_statuses (
    status_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE course.course_statuses OWNER TO postgres;

--
-- TOC entry 5174 (class 0 OID 0)
-- Dependencies: 252
-- Name: TABLE course_statuses; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON TABLE course.course_statuses IS 'Справочная таблица для статусов курсов (Запланировано, В процессе, Завершено).';


--
-- TOC entry 5175 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN course_statuses.status_id; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_statuses.status_id IS 'Уникальный идентификатор статуса';


--
-- TOC entry 5176 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN course_statuses.name; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_statuses.name IS 'Название статуса (например, Запланировано, Завершено)';


--
-- TOC entry 5177 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN course_statuses.created_at; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_statuses.created_at IS 'Дата и время создания записи';


--
-- TOC entry 240 (class 1259 OID 26808)
-- Name: course_topics; Type: TABLE; Schema: course; Owner: postgres
--

CREATE TABLE course.course_topics (
    topic_id integer NOT NULL,
    course_id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(100) NOT NULL,
    material text,
    grade numeric(5,2),
    completed_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT course_topics_grade_check CHECK (((grade >= (0)::numeric) AND (grade <= (5)::numeric)))
);


ALTER TABLE course.course_topics OWNER TO postgres;

--
-- TOC entry 5178 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE course_topics; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON TABLE course.course_topics IS 'Таблица для хранения тем курсов пользователей';


--
-- TOC entry 5179 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.topic_id; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.topic_id IS 'Уникальный идентификатор темы (первичный ключ)';


--
-- TOC entry 5180 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.course_id; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.course_id IS 'Идентификатор курса, к которому относится тема (внешний ключ)';


--
-- TOC entry 5181 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.user_id; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.user_id IS 'Идентификатор пользователя, которому принадлежит тема (внешний ключ)';


--
-- TOC entry 5182 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.title; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.title IS 'Название темы';


--
-- TOC entry 5183 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.material; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.material IS 'Материалы темы (например, текст лекций или ссылки)';


--
-- TOC entry 5184 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.grade; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.grade IS 'Оценка за тему (от 0 до 5)';


--
-- TOC entry 5185 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.completed_date; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.completed_date IS 'Дата завершения темы';


--
-- TOC entry 5186 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.created_at; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.created_at IS 'Дата и время создания темы';


--
-- TOC entry 5187 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN course_topics.updated_at; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.course_topics.updated_at IS 'Дата и время последнего обновления темы';


--
-- TOC entry 238 (class 1259 OID 26793)
-- Name: courses; Type: TABLE; Schema: course; Owner: postgres
--

CREATE TABLE course.courses (
    course_id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(100) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status_id integer NOT NULL
);


ALTER TABLE course.courses OWNER TO postgres;

--
-- TOC entry 5188 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE courses; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON TABLE course.courses IS 'Таблица для хранения курсов пользователей';


--
-- TOC entry 5189 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN courses.course_id; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.courses.course_id IS 'Уникальный идентификатор курса (первичный ключ)';


--
-- TOC entry 5190 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN courses.user_id; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.courses.user_id IS 'Идентификатор пользователя, которому принадлежит курс (внешний ключ)';


--
-- TOC entry 5191 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN courses.title; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.courses.title IS 'Название курса (уникально в рамках пользователя)';


--
-- TOC entry 5192 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN courses.description; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.courses.description IS 'Описание курса';


--
-- TOC entry 5193 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN courses.created_at; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.courses.created_at IS 'Дата и время создания курса';


--
-- TOC entry 5194 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN courses.updated_at; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.courses.updated_at IS 'Дата и время последнего обновления курса';


--
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN courses.status_id; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON COLUMN course.courses.status_id IS 'Идентификатор статуса курса (ссылка на course_statuses)';


--
-- TOC entry 257 (class 1259 OID 27744)
-- Name: course_grades; Type: VIEW; Schema: course; Owner: postgres
--

CREATE VIEW course.course_grades AS
 SELECT c.course_id,
    c.user_id,
    c.title,
    c.description,
    cs.name AS status,
    avg(ct.grade) AS final_grade
   FROM ((course.courses c
     LEFT JOIN course.course_topics ct ON ((c.course_id = ct.course_id)))
     JOIN course.course_statuses cs ON ((c.status_id = cs.status_id)))
  GROUP BY c.course_id, c.user_id, c.title, c.description, cs.name;


ALTER VIEW course.course_grades OWNER TO postgres;

--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 257
-- Name: VIEW course_grades; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON VIEW course.course_grades IS 'Представление, вычисляющее среднюю оценку (final_grade) по темам для каждого курса из таблицы courses. Включает course_id, user_id, title, description и status (из course_statuses). Используется для анализа успеваемости.';


--
-- TOC entry 248 (class 1259 OID 26899)
-- Name: course_progress; Type: VIEW; Schema: course; Owner: postgres
--

CREATE VIEW course.course_progress AS
 SELECT c.course_id,
    c.user_id,
    c.title,
    count(ct.topic_id) AS total_topics,
    count(ct.completed_date) AS completed_topics,
    (((count(ct.completed_date))::double precision / (NULLIF(count(ct.topic_id), 0))::double precision) * (100)::double precision) AS completion_percentage
   FROM (course.courses c
     LEFT JOIN course.course_topics ct ON ((c.course_id = ct.course_id)))
  GROUP BY c.course_id, c.user_id, c.title;


ALTER VIEW course.course_progress OWNER TO postgres;

--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 248
-- Name: VIEW course_progress; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON VIEW course.course_progress IS 'Представление, показывающее прогресс выполнения курсов: общее количество тем (total_topics), завершенные темы (completed_topics) и процент завершения (completion_percentage). Используется для отслеживания прогресса пользователей.';


--
-- TOC entry 239 (class 1259 OID 26807)
-- Name: course_topics_topic_id_seq; Type: SEQUENCE; Schema: course; Owner: postgres
--

CREATE SEQUENCE course.course_topics_topic_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE course.course_topics_topic_id_seq OWNER TO postgres;

--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 239
-- Name: course_topics_topic_id_seq; Type: SEQUENCE OWNED BY; Schema: course; Owner: postgres
--

ALTER SEQUENCE course.course_topics_topic_id_seq OWNED BY course.course_topics.topic_id;


--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 239
-- Name: SEQUENCE course_topics_topic_id_seq; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON SEQUENCE course.course_topics_topic_id_seq IS 'Последовательность для генерации уникальных идентификаторов (topic_id) в таблице course_topics, хранящей темы курсов.';


--
-- TOC entry 237 (class 1259 OID 26792)
-- Name: courses_course_id_seq; Type: SEQUENCE; Schema: course; Owner: postgres
--

CREATE SEQUENCE course.courses_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE course.courses_course_id_seq OWNER TO postgres;

--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 237
-- Name: courses_course_id_seq; Type: SEQUENCE OWNED BY; Schema: course; Owner: postgres
--

ALTER SEQUENCE course.courses_course_id_seq OWNED BY course.courses.course_id;


--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 237
-- Name: SEQUENCE courses_course_id_seq; Type: COMMENT; Schema: course; Owner: postgres
--

COMMENT ON SEQUENCE course.courses_course_id_seq IS 'Последовательность для генерации уникальных идентификаторов (course_id) в таблице courses, хранящей информацию о курсах пользователей.';


--
-- TOC entry 224 (class 1259 OID 26513)
-- Name: finance_categories; Type: TABLE; Schema: finance; Owner: postgres
--

CREATE TABLE finance.finance_categories (
    category_id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    type_id integer NOT NULL
);


ALTER TABLE finance.finance_categories OWNER TO postgres;

--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE finance_categories; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON TABLE finance.finance_categories IS 'Таблица для хранения категорий финансовых операций пользователей';


--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN finance_categories.category_id; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_categories.category_id IS 'Уникальный идентификатор категории (первичный ключ)';


--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN finance_categories.user_id; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_categories.user_id IS 'Идентификатор пользователя, которому принадлежит категория (внешний ключ)';


--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN finance_categories.name; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_categories.name IS 'Название категории (уникально в рамках пользователя)';


--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN finance_categories.created_at; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_categories.created_at IS 'Дата и время создания категории';


--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN finance_categories.updated_at; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_categories.updated_at IS 'Дата и время последнего обновления категории';


--
-- TOC entry 5208 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN finance_categories.type_id; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_categories.type_id IS 'Идентификатор типа категории (ссылка на finance_types)';


--
-- TOC entry 223 (class 1259 OID 26512)
-- Name: finance_categories_category_id_seq; Type: SEQUENCE; Schema: finance; Owner: postgres
--

CREATE SEQUENCE finance.finance_categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE finance.finance_categories_category_id_seq OWNER TO postgres;

--
-- TOC entry 5209 (class 0 OID 0)
-- Dependencies: 223
-- Name: finance_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: finance; Owner: postgres
--

ALTER SEQUENCE finance.finance_categories_category_id_seq OWNED BY finance.finance_categories.category_id;


--
-- TOC entry 5210 (class 0 OID 0)
-- Dependencies: 223
-- Name: SEQUENCE finance_categories_category_id_seq; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON SEQUENCE finance.finance_categories_category_id_seq IS 'Последовательность для генерации уникальных идентификаторов (category_id) в таблице finance_categories, хранящей пользовательские категории финансовых операций.';


--
-- TOC entry 249 (class 1259 OID 27221)
-- Name: finance_types; Type: TABLE; Schema: finance; Owner: postgres
--

CREATE TABLE finance.finance_types (
    type_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_income boolean DEFAULT false NOT NULL
);


ALTER TABLE finance.finance_types OWNER TO postgres;

--
-- TOC entry 5211 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE finance_types; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON TABLE finance.finance_types IS 'Справочная таблица для типов финансовых операций (Доход, Расход). ';


--
-- TOC entry 5212 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN finance_types.type_id; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_types.type_id IS 'Уникальный идентификатор типа';


--
-- TOC entry 5213 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN finance_types.name; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_types.name IS 'Название типа (например, Доход, Расход)';


--
-- TOC entry 5214 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN finance_types.created_at; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finance_types.created_at IS 'Дата и время создания записи';


--
-- TOC entry 226 (class 1259 OID 26527)
-- Name: finances; Type: TABLE; Schema: finance; Owner: postgres
--

CREATE TABLE finance.finances (
    finance_id integer NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    transaction_date date NOT NULL,
    note text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT finances_check_amount CHECK ((amount <> (0)::numeric))
);


ALTER TABLE finance.finances OWNER TO postgres;

--
-- TOC entry 5215 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE finances; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON TABLE finance.finances IS 'Таблица для учета финансовых операций пользователей';


--
-- TOC entry 5216 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.finance_id; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.finance_id IS 'Уникальный идентификатор финансовой операции (первичный ключ)';


--
-- TOC entry 5217 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.user_id; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.user_id IS 'Идентификатор пользователя, совершившего операцию (внешний ключ)';


--
-- TOC entry 5218 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.category_id; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.category_id IS 'Идентификатор категории операции (внешний ключ)';


--
-- TOC entry 5219 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.amount; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.amount IS 'Сумма операции, положительная для доходов, отрицательная для расходов';


--
-- TOC entry 5220 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.transaction_date; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.transaction_date IS 'Дата совершения операции';


--
-- TOC entry 5221 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.note; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.note IS 'Заметка или комментарий к операции';


--
-- TOC entry 5222 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.created_at; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.created_at IS 'Дата и время создания записи об операции';


--
-- TOC entry 5223 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN finances.updated_at; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON COLUMN finance.finances.updated_at IS 'Дата и время последнего обновления записи';


--
-- TOC entry 225 (class 1259 OID 26526)
-- Name: finances_finance_id_seq; Type: SEQUENCE; Schema: finance; Owner: postgres
--

CREATE SEQUENCE finance.finances_finance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE finance.finances_finance_id_seq OWNER TO postgres;

--
-- TOC entry 5224 (class 0 OID 0)
-- Dependencies: 225
-- Name: finances_finance_id_seq; Type: SEQUENCE OWNED BY; Schema: finance; Owner: postgres
--

ALTER SEQUENCE finance.finances_finance_id_seq OWNED BY finance.finances.finance_id;


--
-- TOC entry 5225 (class 0 OID 0)
-- Dependencies: 225
-- Name: SEQUENCE finances_finance_id_seq; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON SEQUENCE finance.finances_finance_id_seq IS 'Последовательность для генерации уникальных идентификаторов (finance_id) в таблице finances, хранящей финансовые операции пользователей.';


--
-- TOC entry 259 (class 1259 OID 28710)
-- Name: financial_summary; Type: VIEW; Schema: finance; Owner: postgres
--

CREATE VIEW finance.financial_summary AS
 SELECT user_id,
    EXTRACT(year FROM transaction_date) AS year,
    EXTRACT(month FROM transaction_date) AS month,
    sum(
        CASE
            WHEN (amount > (0)::numeric) THEN amount
            ELSE (0)::numeric
        END) AS total_income,
    sum(
        CASE
            WHEN (amount < (0)::numeric) THEN (- amount)
            ELSE (0)::numeric
        END) AS total_expense,
    sum(amount) AS balance
   FROM finance.finances f
  GROUP BY user_id, (EXTRACT(year FROM transaction_date)), (EXTRACT(month FROM transaction_date));


ALTER VIEW finance.financial_summary OWNER TO postgres;

--
-- TOC entry 5226 (class 0 OID 0)
-- Dependencies: 259
-- Name: VIEW financial_summary; Type: COMMENT; Schema: finance; Owner: postgres
--

COMMENT ON VIEW finance.financial_summary IS 'Представление, агрегирующее доходы (total_income), расходы (total_expense) и баланс (balance) по пользователям за месяц и год на основе таблицы finances.';


--
-- TOC entry 232 (class 1259 OID 26711)
-- Name: habit_categories; Type: TABLE; Schema: habits; Owner: postgres
--

CREATE TABLE habits.habit_categories (
    category_id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE habits.habit_categories OWNER TO postgres;

--
-- TOC entry 5227 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE habit_categories; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON TABLE habits.habit_categories IS 'Таблица для хранения категорий привычек пользователей';


--
-- TOC entry 5228 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN habit_categories.category_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_categories.category_id IS 'Уникальный идентификатор категории (первичный ключ)';


--
-- TOC entry 5229 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN habit_categories.user_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_categories.user_id IS 'Идентификатор пользователя, которому принадлежит категория (внешний ключ)';


--
-- TOC entry 5230 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN habit_categories.name; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_categories.name IS 'Название категории (уникально в рамках пользователя)';


--
-- TOC entry 5231 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN habit_categories.created_at; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_categories.created_at IS 'Дата и время создания категории';


--
-- TOC entry 5232 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN habit_categories.updated_at; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_categories.updated_at IS 'Дата и время последнего обновления категории';


--
-- TOC entry 231 (class 1259 OID 26710)
-- Name: habit_categories_category_id_seq; Type: SEQUENCE; Schema: habits; Owner: postgres
--

CREATE SEQUENCE habits.habit_categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE habits.habit_categories_category_id_seq OWNER TO postgres;

--
-- TOC entry 5233 (class 0 OID 0)
-- Dependencies: 231
-- Name: habit_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: habits; Owner: postgres
--

ALTER SEQUENCE habits.habit_categories_category_id_seq OWNED BY habits.habit_categories.category_id;


--
-- TOC entry 5234 (class 0 OID 0)
-- Dependencies: 231
-- Name: SEQUENCE habit_categories_category_id_seq; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON SEQUENCE habits.habit_categories_category_id_seq IS 'Последовательность для генерации уникальных идентификаторов (category_id) в таблице habit_categories, хранящей категории привычек пользователей.';


--
-- TOC entry 255 (class 1259 OID 27718)
-- Name: habit_frequencies; Type: TABLE; Schema: habits; Owner: postgres
--

CREATE TABLE habits.habit_frequencies (
    frequency_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE habits.habit_frequencies OWNER TO postgres;

--
-- TOC entry 5235 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE habit_frequencies; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON TABLE habits.habit_frequencies IS 'Справочная таблица для частоты привычек (Ежедневно, Каждые два дня, Еженедельно, Ежемесячно). ';


--
-- TOC entry 5236 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN habit_frequencies.frequency_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_frequencies.frequency_id IS 'Уникальный идентификатор частоты';


--
-- TOC entry 5237 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN habit_frequencies.name; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_frequencies.name IS 'Название частоты (например, Ежедневно, Еженедельно)';


--
-- TOC entry 5238 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN habit_frequencies.created_at; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_frequencies.created_at IS 'Дата и время создания записи';


--
-- TOC entry 236 (class 1259 OID 26744)
-- Name: habit_logs; Type: TABLE; Schema: habits; Owner: postgres
--

CREATE TABLE habits.habit_logs (
    log_id integer NOT NULL,
    habit_id integer NOT NULL,
    log_date date NOT NULL,
    is_completed boolean DEFAULT false,
    note text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE habits.habit_logs OWNER TO postgres;

--
-- TOC entry 5239 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE habit_logs; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON TABLE habits.habit_logs IS 'Таблица для хранения логов выполнения привычек';


--
-- TOC entry 5240 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN habit_logs.log_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_logs.log_id IS 'Уникальный идентификатор лога (первичный ключ)';


--
-- TOC entry 5241 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN habit_logs.habit_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_logs.habit_id IS 'Идентификатор привычки, к которой относится лог (внешний ключ)';


--
-- TOC entry 5242 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN habit_logs.log_date; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_logs.log_date IS 'Дата лога выполнения привычки';


--
-- TOC entry 5243 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN habit_logs.is_completed; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_logs.is_completed IS 'Флаг выполнения привычки в указанную дату (true/false)';


--
-- TOC entry 5244 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN habit_logs.note; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_logs.note IS 'Заметка или комментарий к логу';


--
-- TOC entry 5245 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN habit_logs.created_at; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_logs.created_at IS 'Дата и время создания лога';


--
-- TOC entry 5246 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN habit_logs.updated_at; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habit_logs.updated_at IS 'Дата и время последнего обновления лога';


--
-- TOC entry 235 (class 1259 OID 26743)
-- Name: habit_logs_log_id_seq; Type: SEQUENCE; Schema: habits; Owner: postgres
--

CREATE SEQUENCE habits.habit_logs_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE habits.habit_logs_log_id_seq OWNER TO postgres;

--
-- TOC entry 5247 (class 0 OID 0)
-- Dependencies: 235
-- Name: habit_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: habits; Owner: postgres
--

ALTER SEQUENCE habits.habit_logs_log_id_seq OWNED BY habits.habit_logs.log_id;


--
-- TOC entry 5248 (class 0 OID 0)
-- Dependencies: 235
-- Name: SEQUENCE habit_logs_log_id_seq; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON SEQUENCE habits.habit_logs_log_id_seq IS 'Последовательность для генерации уникальных идентификаторов (log_id) в таблице habit_logs, хранящей записи о выполнении привычек.';


--
-- TOC entry 234 (class 1259 OID 26726)
-- Name: habits; Type: TABLE; Schema: habits; Owner: postgres
--

CREATE TABLE habits.habits (
    habit_id integer NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    name character varying(100) NOT NULL,
    start_date date NOT NULL,
    end_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    frequency_id integer NOT NULL,
    CONSTRAINT habits_check CHECK ((start_date <= end_date))
);


ALTER TABLE habits.habits OWNER TO postgres;

--
-- TOC entry 5249 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE habits; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON TABLE habits.habits IS 'Таблица для хранения привычек пользователей';


--
-- TOC entry 5250 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.habit_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.habit_id IS 'Уникальный идентификатор привычки (первичный ключ)';


--
-- TOC entry 5251 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.user_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.user_id IS 'Идентификатор пользователя, которому принадлежит привычка (внешний ключ)';


--
-- TOC entry 5252 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.category_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.category_id IS 'Идентификатор категории привычки (внешний ключ)';


--
-- TOC entry 5253 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.name; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.name IS 'Название привычки (уникально в рамках пользователя)';


--
-- TOC entry 5254 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.start_date; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.start_date IS 'Дата начала выполнения привычки';


--
-- TOC entry 5255 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.end_date; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.end_date IS 'Дата окончания выполнения привычки (может быть NULL)';


--
-- TOC entry 5256 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.created_at; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.created_at IS 'Дата и время создания привычки';


--
-- TOC entry 5257 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.updated_at; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.updated_at IS 'Дата и время последнего обновления привычки';


--
-- TOC entry 5258 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN habits.frequency_id; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON COLUMN habits.habits.frequency_id IS 'Идентификатор частоты привычки (ссылка на habit_frequencies)';


--
-- TOC entry 233 (class 1259 OID 26725)
-- Name: habits_habit_id_seq; Type: SEQUENCE; Schema: habits; Owner: postgres
--

CREATE SEQUENCE habits.habits_habit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE habits.habits_habit_id_seq OWNER TO postgres;

--
-- TOC entry 5259 (class 0 OID 0)
-- Dependencies: 233
-- Name: habits_habit_id_seq; Type: SEQUENCE OWNED BY; Schema: habits; Owner: postgres
--

ALTER SEQUENCE habits.habits_habit_id_seq OWNED BY habits.habits.habit_id;


--
-- TOC entry 5260 (class 0 OID 0)
-- Dependencies: 233
-- Name: SEQUENCE habits_habit_id_seq; Type: COMMENT; Schema: habits; Owner: postgres
--

COMMENT ON SEQUENCE habits.habits_habit_id_seq IS 'Последовательность для генерации уникальных идентификаторов (habit_id) в таблице habits, хранящей привычки пользователей.';


--
-- TOC entry 251 (class 1259 OID 27686)
-- Name: task_priorities; Type: TABLE; Schema: todo; Owner: postgres
--

CREATE TABLE todo.task_priorities (
    priority_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE todo.task_priorities OWNER TO postgres;

--
-- TOC entry 5261 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE task_priorities; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON TABLE todo.task_priorities IS 'Справочная таблица для приоритетов задач (Низкий, Средний, Высокий).';


--
-- TOC entry 5262 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN task_priorities.priority_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.task_priorities.priority_id IS 'Уникальный идентификатор приоритета';


--
-- TOC entry 5263 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN task_priorities.name; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.task_priorities.name IS 'Название приоритета (например, Низкий, Средний)';


--
-- TOC entry 5264 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN task_priorities.created_at; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.task_priorities.created_at IS 'Дата и время создания записи';


--
-- TOC entry 250 (class 1259 OID 27678)
-- Name: task_statuses; Type: TABLE; Schema: todo; Owner: postgres
--

CREATE TABLE todo.task_statuses (
    status_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE todo.task_statuses OWNER TO postgres;

--
-- TOC entry 5265 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE task_statuses; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON TABLE todo.task_statuses IS 'Справочная таблица для статусов задач (Запланировано, В процессе, Завершено).';


--
-- TOC entry 5266 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN task_statuses.status_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.task_statuses.status_id IS 'Уникальный идентификатор статуса';


--
-- TOC entry 5267 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN task_statuses.name; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.task_statuses.name IS 'Название статуса (например, Запланировано, В процессе)';


--
-- TOC entry 5268 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN task_statuses.created_at; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.task_statuses.created_at IS 'Дата и время создания записи';


--
-- TOC entry 228 (class 1259 OID 26675)
-- Name: todo_categories; Type: TABLE; Schema: todo; Owner: postgres
--

CREATE TABLE todo.todo_categories (
    category_id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE todo.todo_categories OWNER TO postgres;

--
-- TOC entry 5269 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE todo_categories; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON TABLE todo.todo_categories IS 'Таблица для хранения категорий задач пользователей';


--
-- TOC entry 5270 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN todo_categories.category_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todo_categories.category_id IS 'Уникальный идентификатор категории (первичный ключ)';


--
-- TOC entry 5271 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN todo_categories.user_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todo_categories.user_id IS 'Идентификатор пользователя, которому принадлежит категория (внешний ключ)';


--
-- TOC entry 5272 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN todo_categories.name; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todo_categories.name IS 'Название категории (уникально в рамках пользователя)';


--
-- TOC entry 5273 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN todo_categories.created_at; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todo_categories.created_at IS 'Дата и время создания категории';


--
-- TOC entry 5274 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN todo_categories.updated_at; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todo_categories.updated_at IS 'Дата и время последнего обновления категории';


--
-- TOC entry 227 (class 1259 OID 26674)
-- Name: todo_categories_category_id_seq; Type: SEQUENCE; Schema: todo; Owner: postgres
--

CREATE SEQUENCE todo.todo_categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE todo.todo_categories_category_id_seq OWNER TO postgres;

--
-- TOC entry 5275 (class 0 OID 0)
-- Dependencies: 227
-- Name: todo_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: todo; Owner: postgres
--

ALTER SEQUENCE todo.todo_categories_category_id_seq OWNED BY todo.todo_categories.category_id;


--
-- TOC entry 5276 (class 0 OID 0)
-- Dependencies: 227
-- Name: SEQUENCE todo_categories_category_id_seq; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON SEQUENCE todo.todo_categories_category_id_seq IS 'Последовательность для генерации уникальных идентификаторов (category_id) в таблице todo_categories, хранящей категории задач пользователей.';


--
-- TOC entry 230 (class 1259 OID 26689)
-- Name: todos; Type: TABLE; Schema: todo; Owner: postgres
--

CREATE TABLE todo.todos (
    todo_id integer NOT NULL,
    user_id integer NOT NULL,
    category_id integer,
    task text NOT NULL,
    due_date date,
    is_completed boolean DEFAULT false,
    completed_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    task_priority_id integer NOT NULL
);


ALTER TABLE todo.todos OWNER TO postgres;

--
-- TOC entry 5277 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE todos; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON TABLE todo.todos IS 'Таблица для хранения задач пользователей';


--
-- TOC entry 5278 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.todo_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.todo_id IS 'Уникальный идентификатор задачи (первичный ключ)';


--
-- TOC entry 5279 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.user_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.user_id IS 'Идентификатор пользователя, которому принадлежит задача (внешний ключ)';


--
-- TOC entry 5280 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.category_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.category_id IS 'Идентификатор категории задачи (внешний ключ, может быть NULL)';


--
-- TOC entry 5281 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.task; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.task IS 'Описание задачи';


--
-- TOC entry 5282 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.due_date; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.due_date IS 'Дата выполнения задачи (может быть NULL)';


--
-- TOC entry 5283 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.is_completed; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.is_completed IS 'Флаг завершения задачи (true/false)';


--
-- TOC entry 5284 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.completed_date; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.completed_date IS 'Дата завершения задачи (устанавливается триггером при is_completed=true)';


--
-- TOC entry 5285 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.created_at; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.created_at IS 'Дата и время создания задачи';


--
-- TOC entry 5286 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.updated_at; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.updated_at IS 'Дата и время последнего обновления задачи';


--
-- TOC entry 5287 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN todos.task_priority_id; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON COLUMN todo.todos.task_priority_id IS 'Идентификатор приоритета задачи (ссылка на task_priorities)';


--
-- TOC entry 229 (class 1259 OID 26688)
-- Name: todos_todo_id_seq; Type: SEQUENCE; Schema: todo; Owner: postgres
--

CREATE SEQUENCE todo.todos_todo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE todo.todos_todo_id_seq OWNER TO postgres;

--
-- TOC entry 5288 (class 0 OID 0)
-- Dependencies: 229
-- Name: todos_todo_id_seq; Type: SEQUENCE OWNED BY; Schema: todo; Owner: postgres
--

ALTER SEQUENCE todo.todos_todo_id_seq OWNED BY todo.todos.todo_id;


--
-- TOC entry 5289 (class 0 OID 0)
-- Dependencies: 229
-- Name: SEQUENCE todos_todo_id_seq; Type: COMMENT; Schema: todo; Owner: postgres
--

COMMENT ON SEQUENCE todo.todos_todo_id_seq IS 'Последовательность для генерации уникальных идентификаторов (todo_id) в таблице todos, хранящей задачи пользователей.';


--
-- TOC entry 254 (class 1259 OID 27710)
-- Name: expense_categories; Type: TABLE; Schema: trips; Owner: postgres
--

CREATE TABLE trips.expense_categories (
    category_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE trips.expense_categories OWNER TO postgres;

--
-- TOC entry 5290 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE expense_categories; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON TABLE trips.expense_categories IS 'Справочная таблица для категорий расходов поездок (Еда, Транспорт и т.д.). ';


--
-- TOC entry 5291 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN expense_categories.category_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.expense_categories.category_id IS 'Уникальный идентификатор категории';


--
-- TOC entry 5292 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN expense_categories.name; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.expense_categories.name IS 'Название категории (например, Еда, Транспорт)';


--
-- TOC entry 5293 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN expense_categories.created_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.expense_categories.created_at IS 'Дата и время создания записи';


--
-- TOC entry 258 (class 1259 OID 27818)
-- Name: expense_categories_category_id_seq; Type: SEQUENCE; Schema: trips; Owner: postgres
--

CREATE SEQUENCE trips.expense_categories_category_id_seq
    START WITH 16
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE trips.expense_categories_category_id_seq OWNER TO postgres;

--
-- TOC entry 5294 (class 0 OID 0)
-- Dependencies: 258
-- Name: expense_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: trips; Owner: postgres
--

ALTER SEQUENCE trips.expense_categories_category_id_seq OWNED BY trips.expense_categories.category_id;


--
-- TOC entry 253 (class 1259 OID 27702)
-- Name: transportation_types; Type: TABLE; Schema: trips; Owner: postgres
--

CREATE TABLE trips.transportation_types (
    type_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE trips.transportation_types OWNER TO postgres;

--
-- TOC entry 5295 (class 0 OID 0)
-- Dependencies: 253
-- Name: TABLE transportation_types; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON TABLE trips.transportation_types IS 'Справочная таблица для типов транспорта (Самолет, Поезд, Автобус и т.д.). ';


--
-- TOC entry 5296 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN transportation_types.type_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.transportation_types.type_id IS 'Уникальный идентификатор типа';


--
-- TOC entry 5297 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN transportation_types.name; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.transportation_types.name IS 'Название типа (например, Самолет, Поезд)';


--
-- TOC entry 5298 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN transportation_types.created_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.transportation_types.created_at IS 'Дата и время создания записи';


--
-- TOC entry 244 (class 1259 OID 26859)
-- Name: trip_routes; Type: TABLE; Schema: trips; Owner: postgres
--

CREATE TABLE trips.trip_routes (
    route_id integer NOT NULL,
    trip_id integer NOT NULL,
    location_order integer NOT NULL,
    location_name character varying(100) NOT NULL,
    distance_km numeric(10,2),
    cost numeric(10,2),
    arrival_date date,
    departure_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    transportation_type_id integer NOT NULL,
    CONSTRAINT trip_routes_check CHECK ((arrival_date <= departure_date)),
    CONSTRAINT trip_routes_cost_check CHECK ((cost >= (0)::numeric)),
    CONSTRAINT trip_routes_date_check CHECK ((arrival_date <= departure_date))
);


ALTER TABLE trips.trip_routes OWNER TO postgres;

--
-- TOC entry 5299 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE trip_routes; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON TABLE trips.trip_routes IS 'Таблица для хранения маршрутов поездок';


--
-- TOC entry 5300 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.route_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.route_id IS 'Уникальный идентификатор маршрута (первичный ключ)';


--
-- TOC entry 5301 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.trip_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.trip_id IS 'Идентификатор поездки, к которой относится маршрут (внешний ключ)';


--
-- TOC entry 5302 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.location_order; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.location_order IS 'Порядковый номер локации в маршруте (уникально в рамках поездки)';


--
-- TOC entry 5303 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.location_name; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.location_name IS 'Название локации';


--
-- TOC entry 5304 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.distance_km; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.distance_km IS 'Расстояние между локациями маршрута в километрах';


--
-- TOC entry 5305 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.cost; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.cost IS 'Стоимость перемещения (в валюте пользователя)';


--
-- TOC entry 5306 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.arrival_date; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.arrival_date IS 'Дата прибытия в локацию';


--
-- TOC entry 5307 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.departure_date; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.departure_date IS 'Дата отбытия из локации (может быть NULL)';


--
-- TOC entry 5308 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.created_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.created_at IS 'Дата и время создания маршрута';


--
-- TOC entry 5309 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.updated_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.updated_at IS 'Дата и время последнего обновления маршрута';


--
-- TOC entry 5310 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN trip_routes.transportation_type_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_routes.transportation_type_id IS 'Идентификатор типа транспорта (ссылка на transportation_types)';


--
-- TOC entry 242 (class 1259 OID 26846)
-- Name: trips; Type: TABLE; Schema: trips; Owner: postgres
--

CREATE TABLE trips.trips (
    trip_id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(100) NOT NULL,
    start_date date NOT NULL,
    end_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT trips_check CHECK ((start_date <= end_date))
);


ALTER TABLE trips.trips OWNER TO postgres;

--
-- TOC entry 5311 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE trips; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON TABLE trips.trips IS 'Таблица для хранения поездок пользователей';


--
-- TOC entry 5312 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN trips.trip_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trips.trip_id IS 'Уникальный идентификатор поездки (первичный ключ)';


--
-- TOC entry 5313 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN trips.user_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trips.user_id IS 'Идентификатор пользователя, которому принадлежит поездка (внешний ключ)';


--
-- TOC entry 5314 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN trips.name; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trips.name IS 'Название поездки';


--
-- TOC entry 5315 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN trips.start_date; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trips.start_date IS 'Дата начала поездки';


--
-- TOC entry 5316 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN trips.end_date; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trips.end_date IS 'Дата окончания поездки (может быть NULL)';


--
-- TOC entry 5317 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN trips.created_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trips.created_at IS 'Дата и время создания записи о поездке';


--
-- TOC entry 5318 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN trips.updated_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trips.updated_at IS 'Дата и время последнего обновления записи';


--
-- TOC entry 245 (class 1259 OID 26873)
-- Name: trip_costs; Type: VIEW; Schema: trips; Owner: postgres
--

CREATE VIEW trips.trip_costs AS
 SELECT t.trip_id,
    t.user_id,
    t.name,
    t.start_date,
    t.end_date,
    sum(tr.cost) AS total_cost
   FROM (trips.trips t
     LEFT JOIN trips.trip_routes tr ON ((t.trip_id = tr.trip_id)))
  GROUP BY t.trip_id, t.user_id, t.name, t.start_date, t.end_date;


ALTER VIEW trips.trip_costs OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 26880)
-- Name: trip_expenses; Type: TABLE; Schema: trips; Owner: postgres
--

CREATE TABLE trips.trip_expenses (
    expense_id integer NOT NULL,
    route_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    expense_date date NOT NULL,
    note text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expense_category_id integer NOT NULL,
    CONSTRAINT trip_expenses_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE trips.trip_expenses OWNER TO postgres;

--
-- TOC entry 5319 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.expense_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.expense_id IS 'Уникальный идентификатор расхода (первичный ключ)';


--
-- TOC entry 5320 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.route_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.route_id IS 'Идентификатор маршрута, к которому относится расход (внешний ключ)';


--
-- TOC entry 5321 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.amount; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.amount IS 'Сумма расхода (в валюте пользователя)';


--
-- TOC entry 5322 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.expense_date; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.expense_date IS 'Дата расхода';


--
-- TOC entry 5323 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.note; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.note IS 'Заметка или комментарий к расходу';


--
-- TOC entry 5324 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.created_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.created_at IS 'Дата и время создания записи о расходе';


--
-- TOC entry 5325 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.updated_at; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.updated_at IS 'Дата и время последнего обновления записи';


--
-- TOC entry 5326 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN trip_expenses.expense_category_id; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON COLUMN trips.trip_expenses.expense_category_id IS 'Идентификатор категории расхода (ссылка на expense_categories)';


--
-- TOC entry 246 (class 1259 OID 26879)
-- Name: trip_expenses_expense_id_seq; Type: SEQUENCE; Schema: trips; Owner: postgres
--

CREATE SEQUENCE trips.trip_expenses_expense_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE trips.trip_expenses_expense_id_seq OWNER TO postgres;

--
-- TOC entry 5327 (class 0 OID 0)
-- Dependencies: 246
-- Name: trip_expenses_expense_id_seq; Type: SEQUENCE OWNED BY; Schema: trips; Owner: postgres
--

ALTER SEQUENCE trips.trip_expenses_expense_id_seq OWNED BY trips.trip_expenses.expense_id;


--
-- TOC entry 5328 (class 0 OID 0)
-- Dependencies: 246
-- Name: SEQUENCE trip_expenses_expense_id_seq; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON SEQUENCE trips.trip_expenses_expense_id_seq IS 'Последовательность для генерации уникальных идентификаторов (expense_id) в таблице trip_expenses, хранящей расходы на маршруты поездок.';


--
-- TOC entry 243 (class 1259 OID 26858)
-- Name: trip_routes_route_id_seq; Type: SEQUENCE; Schema: trips; Owner: postgres
--

CREATE SEQUENCE trips.trip_routes_route_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE trips.trip_routes_route_id_seq OWNER TO postgres;

--
-- TOC entry 5329 (class 0 OID 0)
-- Dependencies: 243
-- Name: trip_routes_route_id_seq; Type: SEQUENCE OWNED BY; Schema: trips; Owner: postgres
--

ALTER SEQUENCE trips.trip_routes_route_id_seq OWNED BY trips.trip_routes.route_id;


--
-- TOC entry 5330 (class 0 OID 0)
-- Dependencies: 243
-- Name: SEQUENCE trip_routes_route_id_seq; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON SEQUENCE trips.trip_routes_route_id_seq IS 'Последовательность для генерации уникальных идентификаторов (route_id) в таблице trip_routes, хранящей этапы маршрутов поездок.';


--
-- TOC entry 241 (class 1259 OID 26845)
-- Name: trips_trip_id_seq; Type: SEQUENCE; Schema: trips; Owner: postgres
--

CREATE SEQUENCE trips.trips_trip_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE trips.trips_trip_id_seq OWNER TO postgres;

--
-- TOC entry 5331 (class 0 OID 0)
-- Dependencies: 241
-- Name: trips_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: trips; Owner: postgres
--

ALTER SEQUENCE trips.trips_trip_id_seq OWNED BY trips.trips.trip_id;


--
-- TOC entry 5332 (class 0 OID 0)
-- Dependencies: 241
-- Name: SEQUENCE trips_trip_id_seq; Type: COMMENT; Schema: trips; Owner: postgres
--

COMMENT ON SEQUENCE trips.trips_trip_id_seq IS 'Последовательность для генерации уникальных идентификаторов (trip_id) в таблице trips, хранящей информацию о поездках пользователей.';


--
-- TOC entry 256 (class 1259 OID 27726)
-- Name: user_roles; Type: TABLE; Schema: user; Owner: postgres
--

CREATE TABLE "user".user_roles (
    role_id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "user".user_roles OWNER TO postgres;

--
-- TOC entry 5333 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE user_roles; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON TABLE "user".user_roles IS 'Справочная таблица для ролей пользователей';


--
-- TOC entry 5334 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN user_roles.role_id; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".user_roles.role_id IS 'Уникальный идентификатор роли';


--
-- TOC entry 5335 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN user_roles.name; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".user_roles.name IS 'Название роли (например, Администратор, Пользователь)';


--
-- TOC entry 5336 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN user_roles.created_at; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".user_roles.created_at IS 'Дата и время создания записи';


--
-- TOC entry 222 (class 1259 OID 26496)
-- Name: users; Type: TABLE; Schema: user; Owner: postgres
--

CREATE TABLE "user".users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    role_id integer NOT NULL,
    CONSTRAINT users_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))
);


ALTER TABLE "user".users OWNER TO postgres;

--
-- TOC entry 5337 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE users; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON TABLE "user".users IS 'Таблица для хранения информации о пользователях системы';


--
-- TOC entry 5338 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.user_id; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".users.user_id IS 'Уникальный идентификатор пользователя (первичный ключ)';


--
-- TOC entry 5339 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.username; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".users.username IS 'Уникальное имя пользователя (не допускает дубликатов)';


--
-- TOC entry 5340 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.email; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".users.email IS 'Электронная почта пользователя (уникальная, формат проверяется регулярным выражением)';


--
-- TOC entry 5341 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.first_name; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".users.first_name IS 'Имя пользователя';


--
-- TOC entry 5342 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.last_name; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".users.last_name IS 'Фамилия пользователя';


--
-- TOC entry 5343 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.updated_at; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".users.updated_at IS 'Дата и время последнего обновления записи';


--
-- TOC entry 5344 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.role_id; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON COLUMN "user".users.role_id IS 'Идентификатор роли пользователя (ссылка на user_roles)';


--
-- TOC entry 221 (class 1259 OID 26495)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: user; Owner: postgres
--

CREATE SEQUENCE "user".users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "user".users_user_id_seq OWNER TO postgres;

--
-- TOC entry 5345 (class 0 OID 0)
-- Dependencies: 221
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: user; Owner: postgres
--

ALTER SEQUENCE "user".users_user_id_seq OWNED BY "user".users.user_id;


--
-- TOC entry 5346 (class 0 OID 0)
-- Dependencies: 221
-- Name: SEQUENCE users_user_id_seq; Type: COMMENT; Schema: user; Owner: postgres
--

COMMENT ON SEQUENCE "user".users_user_id_seq IS 'Последовательность для генерации уникальных идентификаторов (user_id) в таблице users, хранящей информацию о пользователях системы.';


--
-- TOC entry 4835 (class 2604 OID 26811)
-- Name: course_topics topic_id; Type: DEFAULT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.course_topics ALTER COLUMN topic_id SET DEFAULT nextval('course.course_topics_topic_id_seq'::regclass);


--
-- TOC entry 4832 (class 2604 OID 26796)
-- Name: courses course_id; Type: DEFAULT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.courses ALTER COLUMN course_id SET DEFAULT nextval('course.courses_course_id_seq'::regclass);


--
-- TOC entry 4809 (class 2604 OID 26516)
-- Name: finance_categories category_id; Type: DEFAULT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finance_categories ALTER COLUMN category_id SET DEFAULT nextval('finance.finance_categories_category_id_seq'::regclass);


--
-- TOC entry 4812 (class 2604 OID 26530)
-- Name: finances finance_id; Type: DEFAULT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finances ALTER COLUMN finance_id SET DEFAULT nextval('finance.finances_finance_id_seq'::regclass);


--
-- TOC entry 4822 (class 2604 OID 26714)
-- Name: habit_categories category_id; Type: DEFAULT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_categories ALTER COLUMN category_id SET DEFAULT nextval('habits.habit_categories_category_id_seq'::regclass);


--
-- TOC entry 4828 (class 2604 OID 26747)
-- Name: habit_logs log_id; Type: DEFAULT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_logs ALTER COLUMN log_id SET DEFAULT nextval('habits.habit_logs_log_id_seq'::regclass);


--
-- TOC entry 4825 (class 2604 OID 26729)
-- Name: habits habit_id; Type: DEFAULT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habits ALTER COLUMN habit_id SET DEFAULT nextval('habits.habits_habit_id_seq'::regclass);


--
-- TOC entry 4815 (class 2604 OID 26678)
-- Name: todo_categories category_id; Type: DEFAULT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todo_categories ALTER COLUMN category_id SET DEFAULT nextval('todo.todo_categories_category_id_seq'::regclass);


--
-- TOC entry 4818 (class 2604 OID 26692)
-- Name: todos todo_id; Type: DEFAULT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todos ALTER COLUMN todo_id SET DEFAULT nextval('todo.todos_todo_id_seq'::regclass);


--
-- TOC entry 4853 (class 2604 OID 27819)
-- Name: expense_categories category_id; Type: DEFAULT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.expense_categories ALTER COLUMN category_id SET DEFAULT nextval('trips.expense_categories_category_id_seq'::regclass);


--
-- TOC entry 4844 (class 2604 OID 26883)
-- Name: trip_expenses expense_id; Type: DEFAULT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_expenses ALTER COLUMN expense_id SET DEFAULT nextval('trips.trip_expenses_expense_id_seq'::regclass);


--
-- TOC entry 4841 (class 2604 OID 26862)
-- Name: trip_routes route_id; Type: DEFAULT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_routes ALTER COLUMN route_id SET DEFAULT nextval('trips.trip_routes_route_id_seq'::regclass);


--
-- TOC entry 4838 (class 2604 OID 26849)
-- Name: trips trip_id; Type: DEFAULT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trips ALTER COLUMN trip_id SET DEFAULT nextval('trips.trips_trip_id_seq'::regclass);


--
-- TOC entry 4807 (class 2604 OID 26499)
-- Name: users user_id; Type: DEFAULT; Schema: user; Owner: postgres
--

ALTER TABLE ONLY "user".users ALTER COLUMN user_id SET DEFAULT nextval('"user".users_user_id_seq'::regclass);


--
-- TOC entry 5159 (class 0 OID 27694)
-- Dependencies: 252
-- Data for Name: course_statuses; Type: TABLE DATA; Schema: course; Owner: postgres
--

INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (1, 'Запланировано', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (2, 'В процессе', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (3, 'Завершено', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (4, 'Приостановлено', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (5, 'Отменено', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (6, 'В ожидании', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (7, 'Планируется', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (8, 'В разработке', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (9, 'Тестируется', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (10, 'Архив', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (11, 'Проверяется', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (12, 'Одобрено', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (13, 'Запущено', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (14, 'Ожидает оценки', '2025-05-13 12:24:28.911238');
INSERT INTO course.course_statuses (status_id, name, created_at) VALUES (15, 'Завершено с отличием', '2025-05-13 12:24:28.911238');


--
-- TOC entry 5149 (class 0 OID 26808)
-- Dependencies: 240
-- Data for Name: course_topics; Type: TABLE DATA; Schema: course; Owner: postgres
--

INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (1, 1, 3, 'Введение в алгоритмы', 'Основные понятия, сложность алгоритмов', 4.50, '2025-01-15', '2025-01-10 09:00:00', '2025-01-15 12:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (2, 1, 3, 'Сортировки', 'Пузырьковая, быстрая, сортировка слиянием', 4.75, '2025-01-22', '2025-01-17 09:00:00', '2025-01-22 12:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (3, 1, 3, 'Поиск в графах', 'BFS, DFS, алгоритм Дейкстры', 5.00, '2025-01-29', '2025-01-24 09:00:00', '2025-01-29 12:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (4, 1, 3, 'Динамическое программирование', 'Задача о рюкзаке, числа Фибоначчи', 4.25, '2025-02-05', '2025-01-31 09:00:00', '2025-02-05 12:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (5, 1, 3, 'Жадные алгоритмы', 'Алгоритм Хаффмана, задача о выборе заявок', 4.50, '2025-02-12', '2025-02-07 09:00:00', '2025-02-12 12:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (6, 2, 4, 'Основы HTML', 'Структура документа, теги', NULL, NULL, '2025-02-01 10:00:00', '2025-02-01 10:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (7, 2, 4, 'CSS для начинающих', 'Селекторы, свойства, box model', NULL, NULL, '2025-02-08 10:00:00', '2025-02-08 10:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (8, 2, 4, 'Адаптивный дизайн', 'Медиазапросы, flexbox, grid', 3.75, '2025-02-15', '2025-02-10 10:00:00', '2025-02-15 12:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (9, 2, 4, 'Основы UX/UI', 'Принципы юзабилити, прототипирование', NULL, NULL, '2025-02-17 10:00:00', '2025-02-17 10:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (10, 3, 5, 'Введение в ML', 'Основные понятия, типы задач', 4.00, '2025-03-01', '2025-02-20 11:00:00', '2025-03-01 13:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (11, 3, 5, 'Линейная регрессия', 'Метод наименьших квадратов', 4.25, '2025-03-08', '2025-03-03 11:00:00', '2025-03-08 13:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (12, 3, 5, 'Классификация', 'Логистическая регрессия, SVM', 4.50, '2025-03-15', '2025-03-10 11:00:00', '2025-03-15 13:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (13, 3, 5, 'Деревья решений', 'Построение и интерпретация', NULL, NULL, '2025-03-17 11:00:00', '2025-03-17 11:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (14, 4, 6, 'Синтаксис Python', 'Переменные, операторы, типы данных', 4.75, '2025-03-10', '2025-03-01 14:00:00', '2025-03-10 16:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (15, 4, 6, 'Функции', 'Определение, аргументы, возврат значений', 4.50, '2025-03-17', '2025-03-12 14:00:00', '2025-03-17 16:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (16, 4, 6, 'Работа с файлами', 'Чтение и запись файлов', 4.25, '2025-03-24', '2025-03-19 14:00:00', '2025-03-24 16:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (17, 4, 6, 'ООП в Python', 'Классы, объекты, наследование', NULL, NULL, '2025-03-26 14:00:00', '2025-03-26 14:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (18, 5, 7, 'Личный бюджет', 'Доходы и расходы, планирование', 3.50, '2025-04-05', '2025-04-01 15:00:00', '2025-04-05 17:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (19, 5, 7, 'Инвестиции', 'Основные инструменты, риски', 4.00, '2025-04-12', '2025-04-07 15:00:00', '2025-04-12 17:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (20, 5, 7, 'Кредиты и займы', 'Виды кредитов, переплата', NULL, NULL, '2025-04-14 15:00:00', '2025-04-14 15:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (21, 6, 10, 'Основы сетей', 'Модель OSI, TCP/IP', NULL, NULL, '2025-04-20 16:00:00', '2025-04-20 16:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (22, 6, 10, 'IP-адресация', 'Классы адресов, подсети', 4.25, '2025-04-27', '2025-04-22 16:00:00', '2025-04-27 18:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (23, 7, 11, 'Введение в Java', 'Установка JDK, Hello World', 4.50, '2025-05-01', '2025-04-25 17:00:00', '2025-05-01 19:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (24, 7, 11, 'Типы данных', 'Примитивные типы, объекты', 4.75, '2025-05-08', '2025-05-03 17:00:00', '2025-05-08 19:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (25, 7, 11, 'Управляющие конструкции', 'Условия, циклы', 4.25, '2025-05-15', '2025-05-10 17:00:00', '2025-05-15 19:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (26, 8, 12, 'Основы UX', 'User research, personas', 4.00, '2025-05-05', '2025-05-01 18:00:00', '2025-05-05 20:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (27, 8, 12, 'Инструменты дизайна', 'Figma, Sketch, Adobe XD', 4.50, '2025-05-12', '2025-05-07 18:00:00', '2025-05-12 20:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (28, 9, 13, 'Античное искусство', 'Древняя Греция и Рим', 4.75, '2025-05-10', '2025-05-05 19:00:00', '2025-05-10 21:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (29, 9, 13, 'Возрождение', 'Леонардо, Микеланджело, Рафаэль', 5.00, '2025-05-17', '2025-05-12 19:00:00', '2025-05-17 21:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (30, 10, 14, 'Основы экономики', 'Спрос и предложение', 4.25, '2025-05-15', '2025-05-10 20:00:00', '2025-05-15 22:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (31, 10, 14, 'Макроэкономика', 'ВВП, инфляция, безработица', NULL, NULL, '2025-05-17 20:00:00', '2025-05-17 20:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (32, 11, 15, 'Введение в Data Science', 'Обзор области, инструменты', 4.50, '2025-05-20', '2025-05-15 09:00:00', '2025-05-20 11:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (33, 12, 17, 'Основы DevOps', 'CI/CD, контейнеризация', NULL, NULL, '2025-05-22 10:00:00', '2025-05-22 10:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (34, 13, 18, 'Интерфейс Photoshop', 'Панели инструментов, слои', 3.75, '2025-05-25', '2025-05-20 11:00:00', '2025-05-25 13:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (35, 14, 19, 'SMM стратегии', 'Контент-план, таргетинг', 4.00, '2025-05-27', '2025-05-22 12:00:00', '2025-05-27 14:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (36, 15, 20, 'Введение в мобильную разработку', 'Платформы, инструменты', NULL, NULL, '2025-05-29 13:00:00', '2025-05-29 13:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (37, 16, 22, 'Основы управления проектами', 'Методологии, планирование', 4.25, '2025-06-01', '2025-05-27 14:00:00', '2025-06-01 16:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (38, 17, 23, '3D моделирование для начинающих', 'Интерфейс Blender', 4.50, '2025-06-03', '2025-05-29 15:00:00', '2025-06-03 17:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (39, 18, 24, 'Основы психологии общения', 'Вербальная и невербальная коммуникация', NULL, NULL, '2025-06-05 16:00:00', '2025-06-05 16:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (40, 19, 25, 'Кибербезопасность', 'Основные угрозы, защита', 4.75, '2025-06-07', '2025-06-02 17:00:00', '2025-06-07 19:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (41, 20, 26, 'Введение в Power BI', 'Интерфейс, подключение данных', 4.00, '2025-06-09', '2025-06-04 18:00:00', '2025-06-09 20:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (42, 21, 27, 'Основы SQL', 'SELECT, JOIN, GROUP BY', 4.50, '2025-06-11', '2025-06-06 19:00:00', '2025-06-11 21:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (43, 22, 28, 'Фишинг и социальная инженерия', 'Методы защиты', NULL, NULL, '2025-06-13 20:00:00', '2025-06-13 20:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (44, 23, 29, 'Введение в Unity', 'Интерфейс, создание сцены', 3.75, '2025-06-15', '2025-06-10 21:00:00', '2025-06-15 23:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (45, 24, 30, 'Физика движения', 'Кинематика, динамика', 4.25, '2025-06-17', '2025-06-12 22:00:00', '2025-06-17 00:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (46, 25, 31, 'Основы бухгалтерии', 'Баланс, отчет о прибылях', NULL, NULL, '2025-06-19 23:00:00', '2025-06-19 23:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (47, 26, 32, 'CSS анимации', 'Transitions, keyframes', 4.50, '2025-06-21', '2025-06-16 00:00:00', '2025-06-21 02:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (48, 27, 33, 'Архитектурные паттерны', 'MVC, MVVM, микросервисы', 4.75, '2025-06-23', '2025-06-18 01:00:00', '2025-06-23 03:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (49, 28, 35, 'Типографика в вебе', 'Шрифты, кернинг, интерлиньяж', NULL, NULL, '2025-06-25 02:00:00', '2025-06-25 02:00:00');
INSERT INTO course.course_topics (topic_id, course_id, user_id, title, material, grade, completed_date, created_at, updated_at) VALUES (50, 29, 38, 'SEO оптимизация контента', 'Ключевые слова, метатеги', 4.00, '2025-06-27', '2025-06-22 03:00:00', '2025-06-27 05:00:00');


--
-- TOC entry 5147 (class 0 OID 26793)
-- Dependencies: 238
-- Data for Name: courses; Type: TABLE DATA; Schema: course; Owner: postgres
--

INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (1, 3, 'Алгоритмы', 'Изучение структур данных', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (3, 5, 'Машинное обучение', 'Введение в ML', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (5, 7, 'Финансовая грамотность', 'Курс по управлению личными финансами', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (7, 11, 'Java с нуля', 'Базовые знания Java', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (8, 12, 'UX/UI дизайн', 'Проектирование интерфейсов', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (9, 13, 'История искусств', 'Погружение в историю искусств', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (10, 14, 'Экономика для всех', 'Экономические основы', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (11, 15, 'Data Science', 'Наука о данных', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (14, 19, 'Маркетинг в соцсетях', 'Продвижение в Instagram и TikTok', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (17, 23, '3D-моделирование', 'Создание 3D моделей', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (18, 24, 'Психология общения', 'Навыки эффективного общения', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (28, 35, 'Типография', 'Работа со шрифтами и текстом', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (30, 39, 'JavaScript основы', 'Курс по JS с практикой', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (31, 41, 'Технический английский', 'Термины и лексика для IT', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (32, 42, 'Философия', 'Основы философии', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (33, 43, 'Бизнес-анализ', 'Сбор и анализ требований', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (34, 45, 'Машинное зрение', 'Компьютерное зрение', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (35, 48, 'Интерпретация данных', 'Работа с датасетами', '2025-06-13 17:30:08.289376', '2025-06-13 17:30:08.289376', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (36, 45, 'Разработка REST API', 'Создание API с использованием Flask и Django', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (37, 35, 'NoSQL базы данных', 'Хранение и обработка данных в MongoDB и Firebase', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (38, 9, 'Креативное письмо', 'Развитие навыков литературного письма', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (39, 19, 'Фреймворк Django', 'Создание веб-приложений с Django', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (40, 32, 'Работа с API Telegram', 'Интеграция с мессенджерами', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (41, 29, 'UI-анимации', 'Эффекты и плавность в интерфейсах', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (42, 42, 'Продвинутый Excel', 'Формулы, сводные таблицы и макросы', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (43, 36, 'Курс по TypeScript', 'Работа с типизацией в JavaScript', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (44, 18, 'Публичные выступления', 'Уверенность перед аудиторией', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (45, 25, 'Soft Skills в IT', 'Мягкие навыки: коммуникация, управление временем', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (46, 46, 'Работа с JSON и XML', 'Форматы обмена данными', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (47, 2, 'Разработка на Kotlin', 'Мобильная разработка для Android', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (48, 29, 'Архитектура клиент-сервер', 'Обмен данными между клиентом и сервером', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (49, 39, 'Машинное обучение в финансах', 'Прогнозирование и анализ финансов с помощью ML', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (50, 6, 'Нейросети с нуля', 'Базовые принципы нейросетей и их обучение', '2025-06-13 17:31:21.720938', '2025-06-13 17:31:21.720938', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (2, 4, 'Веб-дизайн', 'Создание сайтов', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (4, 6, 'Основы Python', 'Изучение программирования на Python', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (6, 10, 'Сетевые технологии', 'Настройка сетей и протоколов', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 2);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (12, 17, 'Введение в DevOps', 'Автоматизация процессов разработки', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (13, 18, 'Photoshop для новичков', 'Работа с изображениями', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (16, 22, 'Проектный менеджмент', 'Управление проектами', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (15, 20, 'Разработка мобильных приложений', 'Создание Android и iOS приложений', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (19, 25, 'Информационная безопасность', 'Защита информации', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (20, 26, 'Power BI для аналитиков', 'Визуализация данных', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (21, 27, 'Базы данных MySQL', 'Администрирование баз данных', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (22, 28, 'Кибербезопасность', 'Безопасность в интернете', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (23, 29, 'Игровая разработка', 'Создание игр на Unity', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (24, 30, 'Физика для гуманитариев', 'Физика простыми словами', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (25, 31, 'Финансовый учет', 'Бухгалтерский учет', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 1);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (26, 32, 'Стилизация CSS', 'Оформление интерфейсов', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (27, 33, 'Архитектура ПО', 'Моделирование архитектуры', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);
INSERT INTO course.courses (course_id, user_id, title, description, created_at, updated_at, status_id) VALUES (29, 38, 'SEO-оптимизация', 'Продвижение сайтов', '2025-06-13 17:30:08.289376', '2025-06-13 17:51:17.527082', 3);


--
-- TOC entry 5133 (class 0 OID 26513)
-- Dependencies: 224
-- Data for Name: finance_categories; Type: TABLE DATA; Schema: finance; Owner: postgres
--

INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (17, 30, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-06-13 19:03:24.993625', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (19, 34, 'Продукты', '2025-05-13 19:08:15.817536', '2025-06-13 19:03:24.993625', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (23, 35, 'Продукты', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (28, 37, 'Продукты', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (30, 25, 'Продукты', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (32, 27, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (34, 39, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (36, 28, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (37, 42, 'Продукты', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (39, 21, 'Продукты', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (1, 1, 'Зарплата', '2025-05-13 15:15:21.231663', '2025-05-13 12:02:13.848552', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (3, 3, 'Фриланс', '2025-05-13 00:28:47.342729', '2025-05-13 12:02:13.848552', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (4, 4, 'Коммунальные услуги', '2025-05-13 09:28:55.49417', '2025-05-13 12:02:13.848552', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (8, 8, 'Фриланс', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (10, 10, 'Инвестиции', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 3);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (12, 12, 'Дивиденды', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 14);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (14, 14, 'Премия', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 15);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (15, 15, 'Одежда', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (18, 2, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (20, 10, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (21, 12, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (22, 12, 'Продукты', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (24, 8, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (25, 6, 'Продукты', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (26, 11, 'Продукты', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (27, 14, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (29, 1, 'Продукты', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (31, 3, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (33, 4, 'Продукты', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (35, 15, 'Продукты', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (38, 4, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (40, 5, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (42, 13, 'Зарплата', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (73, 1, 'Аренда жилья', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (75, 3, 'Медицина', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (76, 4, 'Спорт', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (78, 6, 'Техника', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (79, 7, 'Подарки', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (80, 8, 'Хобби', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (82, 10, 'Кафе', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (83, 11, 'Такси', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (84, 12, 'Одежда', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (86, 14, 'Ремонт', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (87, 15, 'Домашние животные', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (88, 1, 'Фриланс', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (90, 3, 'Сбережения', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 4);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (91, 4, 'Кредиты', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 5);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (92, 5, 'Пожертвования', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 6);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (94, 7, 'Подарки', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 8);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (95, 8, 'Штрафы', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 9);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (96, 9, 'Налоги', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 10);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (97, 10, 'Страховка', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 11);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (98, 11, 'Аренда', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 12);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (99, 12, 'Комиссии', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 13);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (100, 13, 'Дивиденды', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 14);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (101, 14, 'Премии', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 15);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (102, 15, 'Бонусы', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (103, 1, 'Подписки', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (104, 2, 'Музыка', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (105, 3, 'Игры', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (41, 44, 'Продукты', '2025-05-13 19:08:15.817536', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (74, 45, 'Образование', '2025-06-13 19:01:10.287568', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (77, 46, 'Книги', '2025-06-13 19:01:10.287568', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (81, 47, 'Кино', '2025-06-13 19:01:10.287568', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (85, 48, 'Косметика', '2025-06-13 19:01:10.287568', '2025-06-13 19:04:31.435453', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (89, 49, 'Инвестиции', '2025-06-13 19:01:10.287568', '2025-06-13 19:04:31.435453', 3);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (93, 22, 'Возврат долга', '2025-06-13 19:01:10.287568', '2025-06-13 19:04:31.435453', 7);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (2, 34, 'Продукты', '2025-05-13 18:32:20.637705', '2025-06-13 19:05:54.367848', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (5, 18, 'Бонусы', '2025-05-13 11:33:49.707702', '2025-06-13 19:05:54.367848', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (6, 22, 'Зарплата', '2025-05-13 12:24:28.911238', '2025-06-13 19:05:54.367848', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (7, 50, 'Продукты', '2025-05-13 12:24:28.911238', '2025-06-13 19:05:54.367848', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (9, 22, 'Транспорт', '2025-05-13 12:24:28.911238', '2025-06-13 19:05:54.367848', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (11, 27, 'Коммунальные услуги', '2025-05-13 12:24:28.911238', '2025-06-13 19:05:54.367848', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (13, 14, 'Развлечения', '2025-05-13 12:24:28.911238', '2025-06-13 19:05:54.367848', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (106, 4, 'Путешествия', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (107, 5, 'Фитнес', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (108, 6, 'Красота', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (109, 7, 'Дети', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (110, 8, 'Автомобиль', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (111, 9, 'Бизнес', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (112, 10, 'Акции', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 3);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (113, 11, 'Облигации', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 3);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (114, 12, 'Недвижимость', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 3);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (115, 13, 'Криптовалюта', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 3);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (116, 14, 'Фонды', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 3);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (117, 15, 'Бизнес-проекты', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 1);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (118, 1, 'Обучение', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (119, 2, 'Курсы', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (120, 3, 'Конференции', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (121, 4, 'Семинары', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);
INSERT INTO finance.finance_categories (category_id, user_id, name, created_at, updated_at, type_id) VALUES (122, 5, 'Вебинары', '2025-06-13 19:01:10.287568', '2025-06-13 19:01:10.287568', 2);


--
-- TOC entry 5156 (class 0 OID 27221)
-- Dependencies: 249
-- Data for Name: finance_types; Type: TABLE DATA; Schema: finance; Owner: postgres
--

INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (2, 'Расход', '2025-05-13 12:02:13.848552', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (3, 'Инвестиции', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (4, 'Сбережения', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (5, 'Кредит', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (6, 'Пожертвования', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (7, 'Возврат долга', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (8, 'Подарок', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (9, 'Штраф', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (10, 'Налоги', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (11, 'Страховка', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (12, 'Аренда', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (13, 'Комиссия', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (14, 'Дивиденды', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (15, 'Премия', '2025-05-13 12:24:28.911238', false);
INSERT INTO finance.finance_types (type_id, name, created_at, is_income) VALUES (1, 'Доход', '2025-05-13 12:02:13.848552', true);


--
-- TOC entry 5135 (class 0 OID 26527)
-- Dependencies: 226
-- Data for Name: finances; Type: TABLE DATA; Schema: finance; Owner: postgres
--

INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (194, 30, 2, -120.50, '2025-06-16', 'Продукты', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (195, 31, 4, -75.30, '2025-06-17', 'Кафе', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (196, 32, 7, -350.00, '2025-06-18', 'Коммуналка', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (197, 33, 9, -200.00, '2025-06-19', 'Транспорт', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (198, 34, 11, -45.90, '2025-06-20', 'Кофе', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (1, 1, 1, 1500.00, '2025-01-15', 'Оклад за январь', '2025-01-15 00:00:47.57304', '2025-05-13 01:08:12.8578');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (2, 2, 2, -500.00, '2025-02-10', 'Покупка еды на неделю', '2025-02-10 00:00:04.303631', '2025-05-13 01:08:12.8578');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (3, 3, 3, 2000.00, '2025-03-05', 'Проект для клиента', '2025-03-05 00:00:01.742209', '2025-05-13 01:08:12.8578');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (4, 4, 4, -300.00, '2025-04-20', 'Оплата света и воды', '2025-04-20 00:00:32.445042', '2025-05-13 01:08:12.8578');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (5, 5, 5, 1000.00, '2025-05-01', 'Годовая премия', '2025-05-01 00:00:41.248741', '2025-05-13 01:08:12.8578');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (199, 35, 13, -600.00, '2025-06-21', 'Одежда', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (200, 36, 15, -90.20, '2025-06-22', 'Книги', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (201, 37, 2, -150.00, '2025-06-23', 'Кино', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (202, 38, 4, -85.40, '2025-06-24', 'Продукты', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (203, 39, 7, -400.00, '2025-06-25', 'Коммуналка', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (204, 40, 9, -250.00, '2025-06-26', 'Такси', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (205, 41, 11, -55.60, '2025-06-27', 'Обед', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (206, 42, 13, -180.00, '2025-06-28', 'Канцелярия', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (207, 43, 15, -95.30, '2025-06-29', 'Продукты', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (208, 44, 2, -500.00, '2025-06-30', 'Коммуналка', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (6, 6, 6, 50000.00, '2025-05-06', 'Зарплата за май', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (7, 7, 7, -1500.00, '2025-05-07', 'Покупка продуктов', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (8, 8, 8, 20000.00, '2025-05-08', 'Оплата за проект', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (9, 9, 9, -800.00, '2025-05-09', 'Проездной', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (10, 10, 10, 10000.00, '2025-05-10', 'Инвестиции в акции', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (11, 11, 11, -3000.00, '2025-05-11', 'Оплата за квартиру', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (12, 12, 12, 5000.00, '2025-05-12', 'Дивиденды от акций', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (13, 13, 13, -2000.00, '2025-05-13', 'Кино и ужин', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (14, 14, 14, 15000.00, '2025-05-14', 'Квартальная премия', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (15, 15, 15, -2500.00, '2025-05-15', 'Покупка обуви', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (16, 3, 39, -2842.94, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (17, 3, 39, -1172.13, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (18, 4, 33, -2807.43, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (19, 4, 33, -2688.26, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (20, 4, 38, 9128.10, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (21, 4, 38, 6126.86, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (22, 5, 30, -1863.29, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (23, 5, 30, -1882.75, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (24, 5, 40, 7574.33, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (25, 5, 40, 5228.22, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (26, 6, 6, 7985.04, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (27, 6, 6, 8742.48, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (28, 6, 25, -2455.33, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (29, 6, 25, -2002.71, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (30, 7, 7, -2836.90, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (31, 7, 7, -2101.38, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (32, 7, 32, 6134.99, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (33, 7, 32, 9730.05, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (34, 8, 19, -2600.81, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (35, 8, 19, -1030.88, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (36, 8, 24, 9587.16, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (37, 8, 24, 6638.79, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (38, 9, 34, 7756.03, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (39, 9, 34, 9569.53, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (40, 9, 37, -2438.93, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (41, 9, 37, -1483.36, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (42, 10, 20, 8479.71, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (43, 10, 20, 6563.07, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (44, 10, 23, -1024.86, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (45, 10, 23, -2947.31, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (46, 11, 17, 6525.83, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (47, 11, 17, 8936.35, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (48, 11, 26, -2631.98, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (49, 11, 26, -2160.12, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (50, 12, 21, 9011.75, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (51, 12, 21, 5547.85, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (52, 12, 22, -1899.39, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (53, 12, 22, -2577.31, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (54, 13, 28, -1071.13, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (55, 13, 28, -1885.11, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (56, 13, 42, 9939.18, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (57, 13, 42, 5334.12, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (58, 14, 27, 8021.73, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (59, 14, 27, 7594.96, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (60, 14, 41, -1333.13, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (61, 14, 41, -1913.79, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (209, 45, 4, -350.00, '2025-07-01', 'Транспорт', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (210, 46, 7, -65.80, '2025-07-02', 'Кофе', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (211, 47, 9, -220.00, '2025-07-03', 'Обед', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (212, 48, 11, -110.20, '2025-07-04', 'Продукты', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (213, 49, 13, -450.00, '2025-07-05', 'Коммуналка', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (214, 50, 15, -300.00, '2025-07-06', 'Транспорт', '2025-06-13 19:22:12.096738', '2025-06-13 19:22:12.096738');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (62, 15, 35, -1562.88, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (63, 15, 35, -2961.60, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (64, 15, 36, 8960.80, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (65, 15, 36, 8174.58, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:08:15.817536', '2025-05-13 19:08:15.817536');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (66, 1, 1, 7886.95, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (67, 1, 1, 9045.37, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (68, 2, 2, -1909.78, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (69, 2, 2, -1973.18, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (70, 6, 6, 8686.57, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (71, 6, 6, 7944.70, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (72, 7, 7, -1480.97, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (73, 7, 7, -2390.93, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (74, 11, 17, 9892.40, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (75, 11, 17, 8790.90, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (76, 2, 18, 8187.90, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (77, 2, 18, 5517.10, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (78, 8, 19, -1225.85, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (79, 8, 19, -1803.49, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (80, 10, 20, 5834.99, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (81, 10, 20, 9721.07, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (82, 12, 21, 9344.13, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (83, 12, 21, 5136.06, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (84, 12, 22, -2965.82, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (85, 12, 22, -2884.77, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (86, 10, 23, -2058.69, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (87, 10, 23, -2046.96, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (88, 8, 24, 6000.71, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (89, 8, 24, 9625.76, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (90, 6, 25, -2799.74, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (91, 6, 25, -2941.99, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (92, 11, 26, -2690.89, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (93, 11, 26, -2673.43, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (94, 14, 27, 7355.36, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (95, 14, 27, 8801.22, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (96, 13, 28, -2715.76, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (97, 13, 28, -2888.52, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (98, 1, 29, -2392.60, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (99, 1, 29, -1653.64, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (100, 5, 30, -1734.48, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (101, 5, 30, -1034.80, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (102, 3, 31, 5898.56, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (103, 3, 31, 9471.04, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (104, 7, 32, 5860.68, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (105, 7, 32, 6954.00, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (107, 4, 33, -1787.12, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (108, 9, 34, 8603.36, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (109, 9, 34, 6462.55, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (110, 15, 35, -1555.21, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (112, 15, 36, 9845.99, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (113, 15, 36, 9896.40, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (115, 9, 37, -2823.74, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (116, 4, 38, 6570.70, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (118, 3, 39, -2924.06, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (119, 3, 39, -2661.09, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (121, 5, 40, 6738.73, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (124, 13, 42, 6031.64, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (125, 13, 42, 9208.93, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-05-13 19:09:04.924032');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (106, 13, 33, -1167.06, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-06-13 19:17:03.193865');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (111, 33, 35, -1975.79, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-06-13 19:17:03.193865');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (114, 12, 37, -1474.36, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-06-13 19:17:03.193865');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (117, 42, 38, 8103.15, '2025-05-05', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-06-13 19:17:03.193865');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (120, 32, 40, 7601.33, '2025-05-15', 'Доход за май 2025', '2025-05-13 19:09:04.924032', '2025-06-13 19:17:03.193865');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (122, 22, 41, -2033.75, '2025-05-15', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-06-13 19:17:03.193865');
INSERT INTO finance.finances (finance_id, user_id, category_id, amount, transaction_date, note, created_at, updated_at) VALUES (123, 43, 41, -1139.60, '2025-05-05', 'Расход за май 2025', '2025-05-13 19:09:04.924032', '2025-06-13 19:17:03.193865');


--
-- TOC entry 5141 (class 0 OID 26711)
-- Dependencies: 232
-- Data for Name: habit_categories; Type: TABLE DATA; Schema: habits; Owner: postgres
--

INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (1, 1, 'Спорт', '2025-05-13 15:52:43.665677', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (2, 2, 'Саморазвитие', '2025-05-13 23:56:54.113403', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (3, 3, 'Здоровье', '2025-05-13 10:30:26.973926', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (4, 4, 'Домашние дела', '2025-05-13 01:45:37.207153', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (5, 5, 'Рукоделие', '2025-05-13 21:08:37.227885', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (6, 6, 'Медитация', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (7, 7, 'Чтение', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (8, 8, 'Прогулки', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (9, 9, 'Изучение языков', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (10, 10, 'Планирование', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (11, 11, 'Фитнес', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (12, 12, 'Кулинария', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (13, 13, 'Творчество', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (14, 14, 'Уборка', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (15, 15, 'Саморазвитие', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (16, 16, 'Утренние ритуалы', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (17, 17, 'Физическая активность', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (18, 18, 'Чтение и учеба', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (19, 19, 'Здоровое питание', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (20, 20, 'Медитация и релаксация', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (21, 21, 'Продуктивность', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (22, 22, 'Личное развитие', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (23, 23, 'Финансовая дисциплина', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (24, 24, 'Творчество', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (25, 25, 'Сон и отдых', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (26, 26, 'Социальные связи', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (27, 27, 'Рабочие привычки', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (28, 28, 'Экология и осознанность', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (29, 29, 'Спорт и фитнес', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (30, 30, 'Самоорганизация', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (31, 31, 'Уход за собой', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (32, 32, 'Изучение языков', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (33, 33, 'Планирование дня', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (34, 34, 'Хобби и увлечения', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (35, 35, 'Духовные практики', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (36, 36, 'Работа над проектами', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (37, 37, 'Физическое здоровье', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (38, 38, 'Чтение книг', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (39, 39, 'Приготовление еды', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (40, 40, 'Ментальное здоровье', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (41, 41, 'Тренировки', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (42, 42, 'Обучение новым навыкам', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (43, 43, 'Экономия времени', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (44, 44, 'Творческие проекты', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (45, 45, 'Семейное время', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (46, 46, 'Рабочая эффективность', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (47, 47, 'Осознанное потребление', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (48, 48, 'Фитнес и спорт', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (49, 49, 'Ежедневное планирование', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');
INSERT INTO habits.habit_categories (category_id, user_id, name, created_at, updated_at) VALUES (50, 50, 'Личная мотивация', '2025-06-13 18:46:48.046688', '2025-06-13 18:46:48.046688');


--
-- TOC entry 5162 (class 0 OID 27718)
-- Dependencies: 255
-- Data for Name: habit_frequencies; Type: TABLE DATA; Schema: habits; Owner: postgres
--

INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (1, 'Ежедневно', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (2, 'Каждые два дня', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (3, 'Еженедельно', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (4, 'Ежемесячно', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (5, 'Каждые 3 дня', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (6, 'Каждые 5 дней', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (7, 'Дважды в неделю', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (8, 'Раз в две недели', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (9, 'Раз в квартал', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (10, 'Раз в полгода', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (11, 'Ежегодно', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (12, 'По будням', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (13, 'По выходным', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (14, 'По необходимости', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_frequencies (frequency_id, name, created_at) VALUES (15, 'Случайно', '2025-05-13 12:24:28.911238');


--
-- TOC entry 5145 (class 0 OID 26744)
-- Dependencies: 236
-- Data for Name: habit_logs; Type: TABLE DATA; Schema: habits; Owner: postgres
--

INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (1, 1, '2025-04-01', true, '30 минут', '2025-04-01 00:00:35.984369', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (2, 2, '2025-04-15', true, '20 страниц', '2025-04-15 00:00:31.283756', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (3, 3, '2025-05-01', false, 'Забыл', '2025-05-01 00:00:05.226033', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (4, 4, '2025-04-20', true, 'Полил все цветы', '2025-04-20 00:00:14.842872', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (5, 5, '2025-05-01', true, 'Свитер почти готов', '2025-05-01 00:00:31.905121', '2025-05-13 01:08:12.8578');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (6, 6, '2025-05-06', true, '10 минут утром', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (7, 7, '2025-05-07', false, 'Не успел', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (8, 8, '2025-05-08', true, 'Прогулка в парке', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (9, 9, '2025-05-09', true, '50 слов выучено', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (10, 10, '2025-05-10', true, 'План на день готов', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (11, 11, '2025-05-11', false, 'Пропустил тренировку', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (12, 12, '2025-05-12', true, 'Приготовил пасту', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (13, 13, '2025-05-13', true, 'Нарисовал эскиз', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (14, 14, '2025-05-14', true, 'Уборка завершена', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (15, 15, '2025-05-15', false, 'Не начал курс', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (16, 1, '2025-06-01', true, 'Завершена утренняя пробежка', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (17, 2, '2025-06-01', false, 'Пропущено из-за встречи', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (18, 3, '2025-06-01', true, 'Прочитано 10 страниц', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (19, 4, '2025-06-01', false, NULL, '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (20, 5, '2025-06-01', true, 'Медитировал 10 минут', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (21, 6, '2025-06-02', true, 'Выпито 2 литра воды', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (22, 7, '2025-06-02', false, 'Слишком устал', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (23, 8, '2025-06-02', true, 'Практиковался на гитаре', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (24, 9, '2025-06-02', true, 'Написано 500 слов', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (25, 10, '2025-06-02', false, NULL, '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (26, 11, '2025-06-03', true, 'Завершена тренировка', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (27, 12, '2025-06-03', false, 'Пропущено из-за дождя', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (28, 13, '2025-06-03', true, 'Изучал испанский', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (29, 14, '2025-06-03', true, 'Приготовил здоровую еду', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (30, 15, '2025-06-03', false, 'Забыл записать', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (31, 1, '2025-06-04', false, NULL, '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (32, 2, '2025-06-04', true, 'Выполнена задача', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (33, 3, '2025-06-04', true, 'Прочитана глава', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (34, 4, '2025-06-04', false, 'Занятый график', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (35, 5, '2025-06-04', true, 'Медитировал', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (36, 6, '2025-06-05', true, 'Хорошо гидратировался', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (37, 7, '2025-06-05', false, NULL, '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (38, 8, '2025-06-05', true, 'Играл 30 минут', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (39, 9, '2025-06-05', true, 'Написал пост в блоге', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (40, 10, '2025-06-05', false, 'Пропущена сессия', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (41, 11, '2025-06-06', true, 'Тренировка в зале', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (42, 12, '2025-06-06', true, 'Пройдено 5 км', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (43, 13, '2025-06-06', false, 'Сегодня нет времени', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (44, 14, '2025-06-06', true, 'Приготовил обед', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (45, 15, '2025-06-06', true, 'Организовал рабочий стол', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (46, 1, '2025-06-07', true, 'Пробежал 3 км', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (47, 2, '2025-06-07', false, NULL, '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (48, 3, '2025-06-07', true, 'Закончил книгу', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (49, 4, '2025-06-07', false, 'Отложено', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');
INSERT INTO habits.habit_logs (log_id, habit_id, log_date, is_completed, note, created_at, updated_at) VALUES (50, 5, '2025-06-07', true, 'Сессия медитации', '2025-06-13 18:42:56.624226', '2025-06-13 18:44:18.787642');


--
-- TOC entry 5143 (class 0 OID 26726)
-- Dependencies: 234
-- Data for Name: habits; Type: TABLE DATA; Schema: habits; Owner: postgres
--

INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (1, 1, 1, 'Утренняя зарядка', '2025-04-01', '2025-06-01', '2025-04-01 00:00:15.425355', '2025-05-13 12:24:28.911238', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (2, 2, 2, 'Чтение книг', '2025-04-15', '2025-05-15', '2025-04-15 00:00:36.626724', '2025-05-13 12:24:28.911238', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (3, 3, 3, 'Пить воду', '2025-05-01', '2025-06-01', '2025-05-01 00:00:09.606167', '2025-05-13 12:24:28.911238', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (4, 4, 4, 'Полив цветов', '2025-04-20', '2025-05-20', '2025-04-20 00:00:42.125709', '2025-05-13 12:24:28.911238', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (5, 5, 5, 'Вязание', '2025-05-01', '2025-06-01', '2025-05-01 00:00:49.422987', '2025-05-13 12:24:28.911238', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (6, 6, 6, 'Медитация 10 минут', '2025-05-06', '2025-07-06', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (7, 7, 7, 'Чтение 30 минут', '2025-05-07', '2025-06-07', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (8, 8, 8, 'Прогулка 5 км', '2025-05-08', '2025-08-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (9, 9, 9, 'Изучение испанского', '2025-05-09', '2025-09-09', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (10, 10, 10, 'Планирование дня', '2025-05-10', '2025-06-10', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (11, 11, 11, 'Тренировка в зале', '2025-05-11', '2025-07-11', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 5);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (12, 12, 12, 'Готовка нового блюда', '2025-05-12', '2025-06-12', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 6);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (13, 13, 13, 'Рисование', '2025-05-13', '2025-08-13', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 7);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (14, 14, 14, 'Генеральная уборка', '2025-05-14', '2025-06-14', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 8);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (15, 15, 15, 'Курсы по психологии', '2025-05-15', '2025-09-15', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 9);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (16, 1, 1, 'Бег по утрам', '2025-06-01', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (17, 2, 2, 'Чтение книг (утром)', '2025-06-01', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (18, 3, 3, 'Медитация (утренняя)', '2025-06-10', '2025-12-01', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (19, 4, 4, 'Игра на гитаре (дома)', '2025-06-05', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (20, 5, 5, 'Йога (утренняя)', '2025-06-01', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (21, 6, 6, 'Плавание (в бассейне)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (22, 7, 7, 'Рисование (акварель)', '2025-06-01', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (23, 8, 8, 'Программирование (Python)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (24, 9, 9, 'Прогулки (в парке)', '2025-06-01', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (25, 10, 10, 'Кулинария (выпечка)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (26, 11, 11, 'Фотография (пейзажи)', '2025-06-01', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (27, 12, 12, 'Танцы (сальса)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (28, 13, 13, 'Фитнес (силовые)', '2025-06-01', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (29, 14, 14, 'Шахматы (онлайн)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (30, 15, 15, 'Садоводство (цветы)', '2025-06-01', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (31, 16, 1, 'Бег (вечерний)', '2025-06-01', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (32, 17, 2, 'Чтение книг (вечером)', '2025-06-10', '2025-12-01', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (33, 18, 3, 'Медитация (вечерняя)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (34, 19, 4, 'Игра на гитаре (на улице)', '2025-06-01', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (35, 20, 5, 'Йога (вечерняя)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (36, 21, 6, 'Плавание (открытая вода)', '2025-06-15', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (37, 22, 7, 'Рисование (масло)', '2025-06-01', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (38, 23, 8, 'Программирование (Java)', '2025-06-10', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (39, 24, 9, 'Прогулки (с собакой)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (40, 25, 10, 'Кулинария (супы)', '2025-06-01', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (41, 26, 11, 'Фотография (портреты)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (42, 27, 12, 'Танцы (танго)', '2025-06-15', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (43, 28, 13, 'Фитнес (кардио)', '2025-06-01', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (44, 29, 14, 'Шахматы (с друзьями)', '2025-06-10', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (45, 30, 15, 'Садоводство (овощи)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (46, 31, 1, 'Бег (утренний)', '2025-06-01', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (47, 32, 2, 'Чтение книг (на работе)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (48, 33, 3, 'Медитация (дневная)', '2025-06-15', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (49, 34, 4, 'Игра на гитаре (электро)', '2025-06-01', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (50, 35, 5, 'Йога (дневная)', '2025-06-10', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (51, 36, 6, 'Плавание (спортзал)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (52, 37, 7, 'Рисование (карандаш)', '2025-06-01', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (53, 38, 8, 'Программирование (JS)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (54, 39, 9, 'Прогулки (лес)', '2025-06-15', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (55, 40, 10, 'Кулинария (десерты)', '2025-06-01', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (56, 41, 11, 'Фотография (макро)', '2025-06-10', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (57, 42, 12, 'Танцы (хип-хоп)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (58, 43, 13, 'Фитнес (йога)', '2025-06-01', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (59, 44, 14, 'Шахматы (турнир)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (60, 45, 15, 'Садоводство (деревья)', '2025-06-15', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (61, 46, 1, 'Бег (дальний)', '2025-06-01', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (62, 47, 2, 'Чтение книг (классика)', '2025-06-10', '2025-11-30', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 4);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (63, 48, 3, 'Медитация (глубокая)', '2025-06-15', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 1);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (64, 49, 4, 'Игра на гитаре (акустика)', '2025-06-01', '2025-12-31', '2025-06-13 14:14:00', '2025-06-13 14:14:00', 2);
INSERT INTO habits.habits (habit_id, user_id, category_id, name, start_date, end_date, created_at, updated_at, frequency_id) VALUES (65, 50, 5, 'Йога (расслабляющая)', '2025-06-10', NULL, '2025-06-13 14:14:00', '2025-06-13 14:14:00', 3);


--
-- TOC entry 5158 (class 0 OID 27686)
-- Dependencies: 251
-- Data for Name: task_priorities; Type: TABLE DATA; Schema: todo; Owner: postgres
--

INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (1, 'Низкий', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (2, 'Средний', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (3, 'Высокий', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (4, 'Критический', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (5, 'Срочный', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (6, 'Очень низкий', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (7, 'Средне-высокий', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (8, 'Средне-низкий', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (9, 'Не срочно', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (10, 'Долгосрочный', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (11, 'Второстепенный', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (12, 'Опциональный', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (13, 'Периодический', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (14, 'Тестовый', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_priorities (priority_id, name, created_at) VALUES (15, 'Экспериментальный', '2025-05-13 12:24:28.911238');


--
-- TOC entry 5157 (class 0 OID 27678)
-- Dependencies: 250
-- Data for Name: task_statuses; Type: TABLE DATA; Schema: todo; Owner: postgres
--

INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (1, 'Запланировано', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (2, 'В процессе', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (3, 'Завершено', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (4, 'Отложено', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (5, 'Отменено', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (6, 'В ожидании', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (7, 'Проверяется', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (8, 'Не начато', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (9, 'На паузе', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (10, 'В процессе проверки', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (11, 'Готово к тестированию', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (12, 'Ожидает одобрения', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (13, 'Запланировано на будущее', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (14, 'В разработке', '2025-05-13 12:24:28.911238');
INSERT INTO todo.task_statuses (status_id, name, created_at) VALUES (15, 'Выполнено частично', '2025-05-13 12:24:28.911238');


--
-- TOC entry 5137 (class 0 OID 26675)
-- Dependencies: 228
-- Data for Name: todo_categories; Type: TABLE DATA; Schema: todo; Owner: postgres
--

INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (1, 1, 'Работа', '2025-05-13 20:16:27.228041', '2025-05-13 01:08:12.8578');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (2, 2, 'Дом', '2025-05-13 01:49:07.099232', '2025-05-13 01:08:12.8578');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (3, 3, 'Здоровье', '2025-05-13 04:58:49.437116', '2025-05-13 01:08:12.8578');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (4, 4, 'Семья', '2025-05-13 21:16:51.176429', '2025-05-13 01:08:12.8578');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (5, 5, 'Личное', '2025-05-13 10:52:35.732458', '2025-05-13 01:08:12.8578');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (6, 6, 'Учёба', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (7, 7, 'Покупки', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (8, 8, 'Путешествия', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (9, 9, 'Работа', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (10, 10, 'Хобби', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (11, 11, 'Фитнес', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (12, 12, 'Семья', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (13, 13, 'Проекты', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (14, 14, 'Здоровье', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (15, 15, 'Финансы', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (16, 1, 'Рабочие задачи', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (17, 2, 'Личные дела', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (18, 3, 'Учеба', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (19, 4, 'Финансы', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (20, 5, 'Здоровье', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (21, 6, 'Покупки', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (22, 7, 'Путешествия', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (23, 8, 'Хобби', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (24, 9, 'Проекты', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (25, 10, 'Спорт', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (26, 11, 'Семья', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (27, 12, 'Работа', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (28, 13, 'Саморазвитие', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (29, 14, 'Домашние дела', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (30, 15, 'Планирование', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (31, 16, 'Организация встреч', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (32, 17, 'Тренинги', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (33, 18, 'Чтение', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (34, 19, 'Путешествия и отдых', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (35, 20, 'Фитнес', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (36, 21, 'Личное время', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (37, 22, 'Рабочие проекты', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (38, 23, 'Обучение', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (39, 24, 'Финансовое планирование', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (40, 25, 'Здоровый образ жизни', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (41, 26, 'Покупки и бюджет', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (42, 27, 'Путешествия и экскурсии', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (43, 28, 'Творчество', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (44, 29, 'Карьера', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (45, 30, 'Семейные дела', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (46, 31, 'Рабочие встречи', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (47, 32, 'Самообразование', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (48, 33, 'Дом и быт', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (49, 34, 'Планирование отпуска', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (50, 35, 'Физическая активность', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (51, 36, 'Личные проекты', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (52, 37, 'Рабочие отчеты', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (53, 38, 'Курсы и тренинги', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (54, 39, 'Чтение и учеба', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (55, 40, 'Путешествия и приключения', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (56, 41, 'Фитнес и здоровье', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (57, 42, 'Личное развитие', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (58, 43, 'Домашние задачи', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (59, 44, 'Финансовые цели', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (60, 45, 'Покупки и планирование', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (61, 46, 'Рабочие задачи 2', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (62, 47, 'Саморазвитие и учеба', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (63, 48, 'Семейные мероприятия', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (64, 49, 'Организация поездок', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');
INSERT INTO todo.todo_categories (category_id, user_id, name, created_at, updated_at) VALUES (65, 50, 'Спорт и активный отдых', '2025-06-13 18:40:25.483164', '2025-06-13 18:40:25.483164');


--
-- TOC entry 5139 (class 0 OID 26689)
-- Dependencies: 230
-- Data for Name: todos; Type: TABLE DATA; Schema: todo; Owner: postgres
--

INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (1, 1, 1, 'Подготовить отчет', '2025-05-02', false, NULL, '2025-05-02 00:00:09.415239', '2025-05-13 12:31:51.479661', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (2, 2, 2, 'Прибраться в комнате', '2025-05-03', true, '2025-05-03', '2025-05-03 00:00:50.398117', '2025-05-13 12:31:51.479661', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (4, 4, 4, 'Купить подарок детям', '2025-05-05', true, '2025-05-05', '2025-05-05 00:00:51.02753', '2025-05-13 12:31:51.479661', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (3, 3, 3, 'Пройти обследование', '2025-05-04', false, '2025-05-13', '2025-05-04 00:00:00.301096', '2025-05-13 14:48:53.151557', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (5, 5, 5, 'Прочитать книгу', '2025-05-06', false, '2025-05-05', '2025-05-06 00:00:48.833832', '2025-05-13 14:49:24.559416', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (6, 6, 6, 'Сдать курсовую', '2025-05-16', false, NULL, '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (7, 7, 7, 'Купить продукты', '2025-05-17', true, '2025-05-17', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (8, 8, 8, 'Забронировать отель', '2025-05-18', false, NULL, '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 4);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (9, 9, 9, 'Подготовить презентацию', '2025-05-19', true, '2025-05-19', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 5);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (10, 10, 10, 'Поиграть на гитаре', '2025-05-20', false, NULL, '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (11, 11, 11, 'Пройти 10 км', '2025-05-21', true, '2025-05-21', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (12, 12, 12, 'Созвониться с родителями', '2025-05-22', false, NULL, '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (13, 13, 13, 'Завершить проект', '2025-05-23', true, '2025-05-23', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 4);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (14, 14, 14, 'Посетить врача', '2025-05-24', false, NULL, '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 5);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (15, 15, 15, 'Составить бюджет', '2025-05-25', true, '2025-05-25', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (16, 1, 1, 'Подготовить презентацию для встречи', '2025-06-20', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (17, 2, 2, 'Купить продукты на неделю', '2025-06-22', true, '2025-06-15', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (18, 3, 3, 'Записаться на курсы английского', '2025-07-01', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (19, 4, 4, 'Позвонить клиенту', '2025-06-25', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (20, 5, 5, 'Проверить отчет по проекту', '2025-07-10', true, '2025-06-14', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (21, 6, 6, 'Организовать встречу команды', '2025-06-30', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (22, 7, 7, 'Зарегистрироваться на вебинар', '2025-07-15', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (23, 8, 8, 'Оплатить коммунальные услуги', '2025-06-28', true, '2025-06-13', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (24, 9, 9, 'Забронировать билеты на концерт', '2025-07-20', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (25, 10, 10, 'Подготовить документы для визы', '2025-08-01', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (26, 11, 11, 'Пройти техосмотр автомобиля', '2025-07-05', true, '2025-06-15', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (27, 12, 12, 'Обновить резюме', '2025-07-25', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (28, 13, 13, 'Запланировать отпуск', '2025-08-10', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (29, 14, 14, 'Купить подарок на день рождения', '2025-06-25', true, '2025-06-14', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (30, 15, 15, 'Провести аудит кода', '2025-07-30', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (31, 16, 1, 'Записаться к врачу', '2025-06-20', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (32, 17, 2, 'Починить ноутбук', '2025-07-10', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (33, 18, 3, 'Прочитать книгу по Python', '2025-08-15', true, '2025-06-13', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (34, 19, 4, 'Организовать семейный ужин', '2025-06-30', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (35, 20, 5, 'Подготовить отчет за квартал', '2025-07-20', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (36, 21, 6, 'Пройти онлайн-курс', '2025-08-05', true, '2025-06-15', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (37, 22, 7, 'Обновить подписку на сервис', '2025-06-25', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (38, 23, 8, 'Проверить почту', '2025-06-20', true, '2025-06-14', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (39, 24, 9, 'Запланировать тренировку', '2025-07-01', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (40, 25, 10, 'Подготовить материалы для встречи', '2025-07-15', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (41, 26, 11, 'Купить новую одежду', '2025-06-30', true, '2025-06-13', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (42, 27, 12, 'Провести уборку дома', '2025-06-25', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (43, 28, 13, 'Записаться на мастер-класс', '2025-07-10', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (44, 29, 14, 'Обновить профиль на сайте', '2025-08-01', true, '2025-06-15', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (45, 30, 15, 'Проверить бюджет на месяц', '2025-07-05', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (46, 31, 1, 'Забронировать отель', '2025-08-10', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (47, 32, 2, 'Провести собрание команды', '2025-07-20', true, '2025-06-14', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (48, 33, 3, 'Пройти тестирование', '2025-06-30', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (49, 34, 4, 'Оформить подписку на журнал', '2025-07-15', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (50, 35, 5, 'Подготовить план проекта', '2025-08-05', true, '2025-06-13', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (51, 36, 6, 'Проверить оборудование', '2025-07-25', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (52, 37, 7, 'Запланировать встречу с клиентом', '2025-06-25', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (53, 38, 8, 'Купить билеты на поезд', '2025-07-10', true, '2025-06-15', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (54, 39, 9, 'Организовать вебинар', '2025-08-15', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (55, 40, 10, 'Провести ревизию документов', '2025-07-20', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (56, 41, 11, 'Записаться на тренинг', '2025-06-30', true, '2025-06-14', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (57, 42, 12, 'Проверить отчеты за месяц', '2025-07-05', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (58, 43, 13, 'Организовать тимбилдинг', '2025-08-01', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (59, 44, 14, 'Обновить программное обеспечение', '2025-07-15', true, '2025-06-13', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (60, 45, 15, 'Провести анализ данных', '2025-06-25', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (61, 46, 1, 'Подготовить материалы для тренинга', '2025-07-30', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (62, 47, 2, 'Провести тестирование ПО', '2025-08-05', true, '2025-06-15', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (63, 48, 3, 'Организовать встречу с партнером', '2025-07-10', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 1);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (64, 49, 4, 'Проверить контракты', '2025-06-30', false, NULL, '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 2);
INSERT INTO todo.todos (todo_id, user_id, category_id, task, due_date, is_completed, completed_date, created_at, updated_at, task_priority_id) VALUES (65, 50, 5, 'Подготовить отчет для руководства', '2025-08-10', true, '2025-06-14', '2025-06-13 18:37:49.375373', '2025-06-13 18:37:49.375373', 3);


--
-- TOC entry 5161 (class 0 OID 27710)
-- Dependencies: 254
-- Data for Name: expense_categories; Type: TABLE DATA; Schema: trips; Owner: postgres
--

INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (1, 'Еда', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (2, 'Проживание', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (3, 'Транспорт', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (4, 'Развлечения', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (5, 'Прочее', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (6, 'Развлечения', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (7, 'Сувениры', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (8, 'Медицина', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (9, 'Страховка', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (10, 'Аренда транспорта', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (11, 'Парковка', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (12, 'Топливо', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (13, 'Общественный транспорт', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (14, 'Экскурсии', '2025-05-13 12:24:28.911238');
INSERT INTO trips.expense_categories (category_id, name, created_at) VALUES (15, 'Прочее', '2025-05-13 12:24:28.911238');


--
-- TOC entry 5160 (class 0 OID 27702)
-- Dependencies: 253
-- Data for Name: transportation_types; Type: TABLE DATA; Schema: trips; Owner: postgres
--

INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (1, 'Самолет', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (2, 'Поезд', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (3, 'Автобус', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (4, 'Машина', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (5, 'Такси', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (6, 'Корабль', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (7, 'Метро', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (8, 'Велосипед', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (9, 'Самокат', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (10, 'Пешком', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (11, 'Автостоп', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (12, 'Трамвай', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (13, 'Троллейбус', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (14, 'Фуникулёр', '2025-05-13 12:24:28.911238');
INSERT INTO trips.transportation_types (type_id, name, created_at) VALUES (15, 'Паром', '2025-05-13 12:24:28.911238');


--
-- TOC entry 5155 (class 0 OID 26880)
-- Dependencies: 247
-- Data for Name: trip_expenses; Type: TABLE DATA; Schema: trips; Owner: postgres
--

INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (1, 1, 50.00, '2025-05-01', 'Обед в поезде', '2025-05-01 00:00:22.630686', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (2, 2, 200.00, '2025-05-02', 'Отель в Питере', '2025-05-02 00:00:15.038531', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (3, 3, 100.00, '2025-05-01', 'Такси в аэропорту', '2025-06-15 00:00:13.54257', '2025-05-13 12:41:05.09709', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (4, 4, 80.00, '2025-05-01', 'Экскурсия', '2025-06-16 00:00:22.928544', '2025-05-13 12:41:05.09709', 4);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (5, 5, 30.00, '2025-05-01', 'Ужин', '2025-07-05 00:00:48.523726', '2025-05-13 12:41:05.09709', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (6, 6, 100.00, '2025-10-01', 'Обед в кафе', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (7, 7, 300.00, '2025-11-01', 'Отель в Крыму', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 5);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (8, 8, 150.00, '2025-12-01', 'Такси в Новосибирске', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (9, 9, 200.00, '2026-01-01', 'Экскурсия в Калининграде', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 14);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (10, 10, 50.00, '2026-02-01', 'Ужин в Волгограде', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (11, 11, 500.00, '2026-03-01', 'Проживание на Алтае', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 5);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (12, 12, 120.00, '2026-04-01', 'Сувениры в Иркутске', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 7);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (13, 13, 80.00, '2026-05-01', 'Транспорт в Перми', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 13);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (14, 14, 90.00, '2026-06-01', 'Обед в Самаре', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (15, 15, 110.00, '2026-07-01', 'Экскурсия в Уфе', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 14);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (16, 1, 1250.50, '2025-06-01', 'Обед в ресторане', '2025-06-01 12:30:00', '2025-06-01 12:30:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (17, 1, 350.00, '2025-06-01', 'Музей', '2025-06-01 15:45:00', '2025-06-01 15:45:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (18, 2, 780.25, '2025-06-02', 'Сувениры', '2025-06-02 10:20:00', '2025-06-02 10:20:00', 4);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (19, 2, 1200.00, '2025-06-02', 'Экскурсия', '2025-06-02 14:00:00', '2025-06-02 14:00:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (20, 3, 450.75, '2025-06-03', 'Завтрак', '2025-06-03 09:15:00', '2025-06-03 09:15:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (21, 3, 600.00, '2025-06-03', 'Такси', '2025-06-03 18:30:00', '2025-06-03 18:30:00', 2);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (22, 4, 890.50, '2025-06-04', 'Ужин', '2025-06-04 20:00:00', '2025-06-04 20:00:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (23, 4, 250.00, '2025-06-04', 'Билеты в театр', '2025-06-04 19:00:00', '2025-06-04 19:00:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (24, 5, 1500.00, '2025-06-05', 'Аренда велосипедов', '2025-06-05 10:00:00', '2025-06-05 10:00:00', 5);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (25, 5, 320.75, '2025-06-05', 'Кофе и десерты', '2025-06-05 16:45:00', '2025-06-05 16:45:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (26, 6, 420.00, '2025-06-06', 'Общественный транспорт', '2025-06-06 08:30:00', '2025-06-06 08:30:00', 2);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (27, 6, 980.50, '2025-06-06', 'Обед с видом на море', '2025-06-06 13:15:00', '2025-06-06 13:15:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (28, 7, 670.25, '2025-06-07', 'Вход в аквапарк', '2025-06-07 11:00:00', '2025-06-07 11:00:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (29, 7, 540.00, '2025-06-07', 'Фотографии', '2025-06-07 15:30:00', '2025-06-07 15:30:00', 4);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (30, 8, 380.75, '2025-06-08', 'Завтрак в кафе', '2025-06-08 09:45:00', '2025-06-08 09:45:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (31, 8, 1250.00, '2025-06-08', 'Подарки родным', '2025-06-08 17:20:00', '2025-06-08 17:20:00', 4);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (32, 9, 290.50, '2025-06-09', 'Мороженое', '2025-06-09 14:10:00', '2025-06-09 14:10:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (33, 9, 850.00, '2025-06-09', 'Билеты на концерт', '2025-06-09 20:00:00', '2025-06-09 20:00:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (34, 10, 430.75, '2025-06-10', 'Обед в парке', '2025-06-10 13:00:00', '2025-06-10 13:00:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (35, 10, 620.00, '2025-06-10', 'Такси в аэропорт', '2025-06-10 18:45:00', '2025-06-10 18:45:00', 2);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (36, 11, 780.50, '2025-06-11', 'Ужин с друзьями', '2025-06-11 19:30:00', '2025-06-11 19:30:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (37, 11, 350.00, '2025-06-11', 'Музей современного искусства', '2025-06-11 11:15:00', '2025-06-11 11:15:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (38, 12, 420.75, '2025-06-12', 'Завтрак в отеле', '2025-06-12 08:30:00', '2025-06-12 08:30:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (39, 12, 950.00, '2025-06-12', 'Экскурсия по городу', '2025-06-12 10:00:00', '2025-06-12 10:00:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (40, 13, 580.50, '2025-06-13', 'Обед в кафе', '2025-06-13 13:45:00', '2025-06-13 13:45:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (41, 13, 320.00, '2025-06-13', 'Сувениры', '2025-06-13 16:20:00', '2025-06-13 16:20:00', 4);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (42, 14, 670.75, '2025-06-14', 'Ужин с видом на город', '2025-06-14 20:00:00', '2025-06-14 20:00:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (43, 14, 450.00, '2025-06-14', 'Такси до отеля', '2025-06-14 22:30:00', '2025-06-14 22:30:00', 2);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (44, 15, 380.50, '2025-06-15', 'Завтрак в постель', '2025-06-15 09:00:00', '2025-06-15 09:00:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (45, 15, 1250.00, '2025-06-15', 'Шоппинг', '2025-06-15 12:00:00', '2025-06-15 12:00:00', 4);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (46, 16, 290.75, '2025-06-16', 'Кофе брейк', '2025-06-16 11:30:00', '2025-06-16 11:30:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (47, 16, 850.00, '2025-06-16', 'Билеты в кино', '2025-06-16 19:00:00', '2025-06-16 19:00:00', 3);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (48, 17, 430.50, '2025-06-17', 'Обед на пляже', '2025-06-17 13:15:00', '2025-06-17 13:15:00', 1);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (49, 17, 620.00, '2025-06-17', 'Аренда зонтика', '2025-06-17 14:30:00', '2025-06-17 14:30:00', 5);
INSERT INTO trips.trip_expenses (expense_id, route_id, amount, expense_date, note, created_at, updated_at, expense_category_id) VALUES (50, 18, 780.75, '2025-06-18', 'Ужин в ресторане', '2025-06-18 20:45:00', '2025-06-18 20:45:00', 1);


--
-- TOC entry 5153 (class 0 OID 26859)
-- Dependencies: 244
-- Data for Name: trip_routes; Type: TABLE DATA; Schema: trips; Owner: postgres
--

INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (1, 1, 1, 'Москва', 700.00, 500.00, '2025-05-01', '2025-05-01', '2025-05-01 00:00:12.853545', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (2, 1, 2, 'Санкт-Петербург', 50.00, 200.00, '2025-05-02', '2025-05-09', '2025-05-02 00:00:49.829356', '2025-05-13 12:24:28.911238', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (3, 2, 1, 'Ростов', 1200.00, 3000.00, '2025-06-15', '2025-06-15', '2025-06-15 00:00:48.216098', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (4, 2, 2, 'Сочи', 20.00, 500.00, '2025-06-16', '2025-06-21', '2025-06-16 00:00:34.268767', '2025-05-13 12:24:28.911238', 5);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (5, 3, 1, 'Казань', 800.00, 600.00, '2025-07-05', '2025-07-11', '2025-07-05 00:00:27.810083', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (6, 6, 1, 'Екатеринбург', 1400.00, 800.00, '2025-10-01', '2025-10-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (7, 7, 1, 'Симферополь', 1800.00, 2500.00, '2025-11-01', '2025-11-10', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (8, 8, 1, 'Новосибирск', 3000.00, 3500.00, '2025-12-01', '2025-12-07', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (9, 9, 1, 'Калининград', 1200.00, 2000.00, '2026-01-01', '2026-01-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (10, 10, 1, 'Волгоград', 1000.00, 600.00, '2026-02-01', '2026-02-06', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (11, 11, 1, 'Горно-Алтайск', 3500.00, 4000.00, '2026-03-01', '2026-03-10', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (12, 12, 1, 'Иркутск', 4200.00, 4500.00, '2026-04-01', '2026-04-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 1);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (13, 13, 1, 'Пермь', 1400.00, 700.00, '2026-05-01', '2026-05-06', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (14, 14, 1, 'Самара', 1000.00, 600.00, '2026-06-01', '2026-06-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (15, 15, 1, 'Уфа', 1200.00, 800.00, '2026-07-01', '2026-07-07', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238', 2);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (16, 16, 1, 'Лиссабон, Португалия', 900.50, 1200.00, '2025-06-14', '2025-06-15', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (17, 16, 2, 'Порту, Португалия', 300.75, 400.00, '2025-06-16', '2025-06-17', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (18, 17, 1, 'Барселона, Испания', 1100.20, 1500.00, '2025-06-18', '2025-06-19', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (19, 17, 2, 'Валенсия, Испания', 350.30, 500.00, '2025-06-20', '2025-06-21', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (20, 18, 1, 'Афины, Греция', 1300.40, 1800.00, '2025-06-22', '2025-06-23', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (21, 18, 2, 'Салоники, Греция', 500.60, 700.00, '2025-06-24', '2025-06-25', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (22, 19, 1, 'Стокгольм, Швеция', 800.70, 1100.00, '2025-06-26', '2025-06-27', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (23, 19, 2, 'Гётеборг, Швеция', 400.80, 600.00, '2025-06-28', '2025-06-29', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (24, 20, 1, 'Копенгаген, Дания', 700.90, 1000.00, '2025-06-30', '2025-07-01', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (25, 20, 2, 'Оденсе, Дания', 200.10, 300.00, '2025-07-02', '2025-07-03', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (26, 21, 1, 'Брюссель, Бельгия', 900.20, 1300.00, '2025-07-04', '2025-07-05', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (27, 21, 2, 'Антверпен, Бельгия', 50.30, 100.00, '2025-07-06', '2025-07-07', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (28, 22, 1, 'Женева, Швейцария', 1100.40, 1600.00, '2025-07-08', '2025-07-09', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (29, 22, 2, 'Цюрих, Швейцария', 300.50, 500.00, '2025-07-10', '2025-07-11', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (30, 23, 1, 'Милан, Италия', 1200.60, 1700.00, '2025-07-12', '2025-07-13', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (31, 23, 2, 'Флоренция, Италия', 400.70, 600.00, '2025-07-14', '2025-07-15', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (32, 24, 1, 'Варна, Болгария', 800.80, 1100.00, '2025-06-14', '2025-06-15', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (33, 24, 2, 'София, Болгария', 450.90, 700.00, '2025-06-16', '2025-06-17', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (34, 25, 1, 'Белград, Сербия', 1000.10, 1400.00, '2025-06-18', '2025-06-19', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (35, 25, 2, 'Нови-Сад, Сербия', 90.20, 200.00, '2025-06-20', '2025-06-21', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (36, 26, 1, 'Загреб, Хорватия', 1100.30, 1500.00, '2025-06-22', '2025-06-23', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (37, 26, 2, 'Сплит, Хорватия', 300.40, 500.00, '2025-06-24', '2025-06-25', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (38, 27, 1, 'Будапешт, Венгрия', 900.50, 1300.00, '2025-06-26', '2025-06-27', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (39, 27, 2, 'Дебрецен, Венгрия', 220.60, 400.00, '2025-06-28', '2025-06-29', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (40, 28, 1, 'Любляна, Словения', 800.70, 1200.00, '2025-06-30', '2025-07-01', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (41, 28, 2, 'Марибор, Словения', 150.80, 300.00, '2025-07-02', '2025-07-03', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (42, 29, 1, 'Братислава, Словакия', 1000.90, 1400.00, '2025-07-04', '2025-07-05', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (43, 29, 2, 'Кошице, Словакия', 400.10, 600.00, '2025-07-06', '2025-07-07', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (44, 30, 1, 'Таллин, Эстония', 900.20, 1300.00, '2025-07-08', '2025-07-09', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (45, 30, 2, 'Тарту, Эстония', 180.30, 300.00, '2025-07-10', '2025-07-11', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (46, 31, 1, 'Вильнюс, Литва', 1100.40, 1600.00, '2025-07-12', '2025-07-13', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (47, 31, 2, 'Каунас, Литва', 100.50, 200.00, '2025-07-14', '2025-07-15', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (48, 32, 1, 'Рига, Латвия', 900.60, 1300.00, '2025-06-14', '2025-06-15', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (49, 32, 2, 'Даугавпилс, Латвия', 200.70, 400.00, '2025-06-16', '2025-06-17', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);
INSERT INTO trips.trip_routes (route_id, trip_id, location_order, location_name, distance_km, cost, arrival_date, departure_date, created_at, updated_at, transportation_type_id) VALUES (50, 33, 1, 'Кишенёв, Молдова', 1000.80, 1400.00, '2025-06-18', '2025-06-19', '2025-06-13 17:14:00', '2025-06-13 17:14:00', 3);


--
-- TOC entry 5151 (class 0 OID 26846)
-- Dependencies: 242
-- Data for Name: trips; Type: TABLE DATA; Schema: trips; Owner: postgres
--

INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (1, 1, 'Путешествие в Санкт-Петербург', '2025-05-01', '2025-05-10', '2025-05-01 00:00:32.463107', '2025-05-13 01:08:12.8578');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (2, 2, 'Поездка в Сочи', '2025-06-15', '2025-06-22', '2025-06-15 00:00:07.199335', '2025-05-13 01:08:12.8578');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (3, 3, 'Отдых в Казани', '2025-07-05', '2025-07-12', '2025-07-05 00:00:02.808951', '2025-05-13 01:08:12.8578');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (4, 4, 'Экскурсия в Москву', '2025-08-01', '2025-08-20', '2025-08-01 00:00:36.652013', '2025-05-13 01:08:12.8578');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (5, 5, 'Поход на Байкал', '2025-09-10', '2025-09-18', '2025-09-10 00:00:08.886786', '2025-05-13 01:08:12.8578');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (6, 6, 'Поездка в Екатеринбург', '2025-10-01', '2025-10-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (7, 7, 'Отдых в Крыму', '2025-11-01', '2025-11-10', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (8, 8, 'Экскурсия в Новосибирск', '2025-12-01', '2025-12-07', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (9, 9, 'Поездка в Калининград', '2026-01-01', '2026-01-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (10, 10, 'Путешествие в Волгоград', '2026-02-01', '2026-02-06', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (11, 11, 'Отдых на Алтае', '2026-03-01', '2026-03-10', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (12, 12, 'Поездка в Иркутск', '2026-04-01', '2026-04-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (13, 13, 'Экскурсия в Пермь', '2026-05-01', '2026-05-06', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (14, 14, 'Путешествие в Самару', '2026-06-01', '2026-06-08', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (15, 15, 'Отдых в Уфе', '2026-07-01', '2026-07-07', '2025-05-13 12:24:28.911238', '2025-05-13 12:24:28.911238');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (16, 16, 'Отпуск в Греции', '2025-07-01', '2025-07-15', '2025-06-01 10:00:00', '2025-06-01 10:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (17, 17, 'Деловая поездка в Берлин', '2025-07-05', '2025-07-08', '2025-06-02 11:00:00', '2025-06-02 11:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (18, 18, 'Горный поход', '2025-07-10', '2025-07-20', '2025-06-03 12:00:00', '2025-06-03 12:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (19, 19, 'Пляжный отдых в Турции', '2025-07-15', '2025-07-25', '2025-06-04 13:00:00', '2025-06-04 13:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (20, 20, 'Фестиваль в Барселоне', '2025-07-20', '2025-07-27', '2025-06-05 14:00:00', '2025-06-05 14:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (21, 21, 'Круиз по Средиземному морю', '2025-08-01', '2025-08-15', '2025-06-06 15:00:00', '2025-06-06 15:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (22, 22, 'Гастрономический тур по Италии', '2025-08-05', '2025-08-12', '2025-06-07 16:00:00', '2025-06-07 16:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (23, 23, 'Экскурсия по Праге', '2025-08-10', '2025-08-13', '2025-06-08 17:00:00', '2025-06-08 17:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (24, 24, 'Сёрфинг в Португалии', '2025-08-15', '2025-08-25', '2025-06-09 18:00:00', '2025-06-09 18:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (25, 25, 'Конференция в Лондоне', '2025-08-20', '2025-08-23', '2025-06-10 19:00:00', '2025-06-10 19:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (26, 26, 'Романтический уикенд в Париже', '2025-09-01', '2025-09-04', '2025-06-11 20:00:00', '2025-06-11 20:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (27, 27, 'Сафари в Кении', '2025-09-05', '2025-09-15', '2025-06-12 21:00:00', '2025-06-12 21:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (28, 28, 'Горнолыжный курорт в Альпах', '2025-09-10', '2025-09-20', '2025-06-13 22:00:00', '2025-06-13 22:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (29, 29, 'Экотуризм в Норвегии', '2025-09-15', '2025-09-25', '2025-06-14 23:00:00', '2025-06-14 23:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (30, 30, 'Шопинг в Милане', '2025-09-20', '2025-09-25', '2025-06-15 00:00:00', '2025-06-15 00:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (31, 31, 'Йога-тур в Индию', '2025-10-01', '2025-10-15', '2025-06-16 01:00:00', '2025-06-16 01:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (32, 32, 'Фотоэкспедиция в Исландию', '2025-10-05', '2025-10-12', '2025-06-17 02:00:00', '2025-06-17 02:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (33, 33, 'Семейный отдых в Диснейленде', '2025-10-10', '2025-10-17', '2025-06-18 03:00:00', '2025-06-18 03:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (34, 34, 'Деловой визит в Нью-Йорк', '2025-10-15', '2025-10-20', '2025-06-19 04:00:00', '2025-06-19 04:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (35, 35, 'Культурный тур по Японии', '2025-10-20', '2025-11-05', '2025-06-20 05:00:00', '2025-06-20 05:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (36, 36, 'Велосипедный тур по Нидерландам', '2025-11-01', '2025-11-10', '2025-06-21 06:00:00', '2025-06-21 06:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (37, 37, 'Свадебное путешествие на Мальдивы', '2025-11-05', '2025-11-15', '2025-06-22 07:00:00', '2025-06-22 07:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (38, 38, 'Сплав по реке в Канаде', '2025-11-10', '2025-11-20', '2025-06-23 08:00:00', '2025-06-23 08:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (39, 39, 'Рождественские ярмарки в Германии', '2025-12-01', '2025-12-08', '2025-06-24 09:00:00', '2025-06-24 09:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (40, 40, 'Новый год в Дубае', '2025-12-25', '2026-01-05', '2025-06-25 10:00:00', '2025-06-25 10:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (41, 41, 'Экскурсия по древним городам Мексики', '2026-01-10', '2026-01-20', '2025-06-26 11:00:00', '2025-06-26 11:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (42, 42, 'Сноркелинг на Большом Барьерном рифе', '2026-01-15', '2026-01-25', '2025-06-27 12:00:00', '2025-06-27 12:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (43, 43, 'Гастротур по Таиланду', '2026-02-01', '2026-02-15', '2025-06-28 13:00:00', '2025-06-28 13:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (44, 44, 'Фототур по Марокко', '2026-02-05', '2026-02-12', '2025-06-29 14:00:00', '2025-06-29 14:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (45, 45, 'Серфинг в Индонезии', '2026-02-10', '2026-02-25', '2025-06-30 15:00:00', '2025-06-30 15:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (46, 46, 'Паломничество в Иерусалим', '2026-03-01', '2026-03-10', '2025-07-01 16:00:00', '2025-07-01 16:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (47, 47, 'Винный тур по Франции', '2026-03-05', '2026-03-15', '2025-07-02 17:00:00', '2025-07-02 17:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (48, 48, 'Треккинг в Непале', '2026-03-10', '2026-03-25', '2025-07-03 18:00:00', '2025-07-03 18:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (49, 49, 'Культурный обмен в Южной Корее', '2026-03-15', '2026-03-30', '2025-07-04 19:00:00', '2025-07-04 19:00:00');
INSERT INTO trips.trips (trip_id, user_id, name, start_date, end_date, created_at, updated_at) VALUES (50, 50, 'Яхтинг в Хорватии', '2026-04-01', '2026-04-15', '2025-07-05 20:00:00', '2025-07-05 20:00:00');


--
-- TOC entry 5163 (class 0 OID 27726)
-- Dependencies: 256
-- Data for Name: user_roles; Type: TABLE DATA; Schema: user; Owner: postgres
--

INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (1, 'Администратор', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (2, 'Пользователь', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (3, 'Модератор', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (4, 'Гость', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (5, 'Редактор', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (6, 'Аналитик', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (7, 'Тестировщик', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (8, 'Разработчик', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (9, 'Менеджер', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (10, 'Дизайнер', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (11, 'Контент-менеджер', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (12, 'Маркетолог', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (13, 'Администратор БД', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (14, 'Системный администратор', '2025-05-13 12:24:28.911238');
INSERT INTO "user".user_roles (role_id, name, created_at) VALUES (15, 'Поддержка', '2025-05-13 12:24:28.911238');


--
-- TOC entry 5131 (class 0 OID 26496)
-- Dependencies: 222
-- Data for Name: users; Type: TABLE DATA; Schema: user; Owner: postgres
--

INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (1, 'ivan_ivanov', 'ivan@example.com', 'Иван', 'Иванов', '2025-05-13 12:24:28.911238', 1);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (2, 'maria_petrova', 'maria@example.com', 'Мария', 'Петрова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (3, 'алексей_смирнов', 'alexey@example.com', 'Алексей', 'Смирнов', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (4, 'елена_кузнецова', 'elena@example.com', 'Елена', 'Кузнецова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (5, 'дмитрий_соколов', 'dmitry@example.com', 'Дмитрий', 'Соколов', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (6, 'anna_morozova', 'anna@example.com', 'Анна', 'Морозова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (7, 'pavel_volkov', 'pavel@example.com', 'Павел', 'Волков', '2025-05-13 12:24:28.911238', 3);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (8, 'olga_fedorova', 'olga@example.com', 'Ольга', 'Федорова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (9, 'sergey_kovalev', 'sergey@example.com', 'Сергей', 'Ковалев', '2025-05-13 12:24:28.911238', 4);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (10, 'natalia_belova', 'natalia@example.com', 'Наталья', 'Белова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (11, 'viktor_egorov', 'viktor@example.com', 'Виктор', 'Егоров', '2025-05-13 12:24:28.911238', 5);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (12, 'ekaterina_smirnova', 'ekaterina@example.com', 'Екатерина', 'Смирнова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (13, 'mikhail_popov', 'mikhail@example.com', 'Михаил', 'Попов', '2025-05-13 12:24:28.911238', 6);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (14, 'tatyana_ivanova', 'tatyana@example.com', 'Татьяна', 'Иванова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (15, 'andrey_zaytsev', 'andrey@example.com', 'Андрей', 'Зайцев', '2025-05-13 12:24:28.911238', 7);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (16, 'alex_sokolov', 'alex.sokolov@example.com', 'Александр', 'Соколов', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (17, 'olga_kuzmina', 'olga.kuzmina@example.com', 'Ольга', 'Кузьмина', '2025-05-13 12:24:28.911238', 3);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (18, 'dmitry_levin', 'dmitry.levin@example.com', 'Дмитрий', 'Левин', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (19, 'natalia_orlova', 'natalia.orlova@example.com', 'Наталья', 'Орлова', '2025-05-13 12:24:28.911238', 4);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (20, 'sergey_moroz', 'sergey.moroz@example.com', 'Сергей', 'Мороз', '2025-05-13 12:24:28.911238', 5);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (21, 'anna_petrenko', 'anna.petrenko@example.com', 'Анна', 'Петренко', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (22, 'viktor_novikov', 'viktor.novikov@example.com', 'Виктор', 'Новиков', '2025-05-13 12:24:28.911238', 6);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (23, 'elena_smirnova', 'elena.smirnova@example.com', 'Елена', 'Смирнова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (24, 'mikhail_gusev', 'mikhail.gusev@example.com', 'Михаил', 'Гусев', '2025-05-13 12:24:28.911238', 7);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (25, 'tatyana_vasileva', 'tatyana.vasileva@example.com', 'Татьяна', 'Васильева', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (26, 'andrey_pavlov', 'andrey.pavlov@example.com', 'Андрей', 'Павлов', '2025-05-13 12:24:28.911238', 8);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (27, 'irina_frolova', 'irina.frolova@example.com', 'Ирина', 'Фролова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (28, 'pavel_krylov', 'pavel.krylov@example.com', 'Павел', 'Крылов', '2025-05-13 12:24:28.911238', 9);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (29, 'julia_romanova', 'julia.romanova@example.com', 'Юлия', 'Романова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (30, 'roman_zotov', 'roman.zotov@example.com', 'Роман', 'Зотов', '2025-05-13 12:24:28.911238', 10);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (31, 'ekaterina_bondarenko', 'ekaterina.bondarenko@example.com', 'Екатерина', 'Бондаренко', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (32, 'igor_sergeev', 'igor.sergeev@example.com', 'Игорь', 'Сергеев', '2025-05-13 12:24:28.911238', 11);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (33, 'maria_ivanova2', 'maria.ivanova2@example.com', 'Мария', 'Иванова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (34, 'alexey_kuznetsov', 'alexey.kuznetsov@example.com', 'Алексей', 'Кузнецов', '2025-05-13 12:24:28.911238', 12);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (35, 'olga_petrova2', 'olga.petrova2@example.com', 'Ольга', 'Петрова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (36, 'dmitry_smirnov', 'dmitry.smirnov@example.com', 'Дмитрий', 'Смирнов', '2025-05-13 12:24:28.911238', 13);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (37, 'natalia_kuzmina', 'natalia.kuzmina@example.com', 'Наталья', 'Кузьмина', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (38, 'sergey_orlov', 'sergey.orlov@example.com', 'Сергей', 'Орлов', '2025-05-13 12:24:28.911238', 14);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (39, 'anna_levina', 'anna.levina@example.com', 'Анна', 'Левина', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (40, 'viktor_morozov', 'viktor.morozov@example.com', 'Виктор', 'Морозов', '2025-05-13 12:24:28.911238', 15);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (41, 'elena_novikova', 'elena.novikova@example.com', 'Елена', 'Новикова', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (44, 'andrey_pavlov2', 'andrey.pavlov2@example.com', 'Андрей', 'Павлов', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (46, 'pavel_krylov2', 'pavel.krylov2@example.com', 'Павел', 'Крылов', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (49, 'ekaterina_bondar', 'ekaterina.bondar@example.com', 'Екатерина', 'Бондарь', '2025-05-13 12:24:28.911238', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (48, 'roman_zotova', 'roman.zotova@example.com', 'Роман', 'Зотов', '2025-06-13 17:07:55.897985', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (50, 'igor_sergeeva', 'igor.sergeeva@example.com', 'Игорь', 'Сергеев', '2025-06-13 17:07:55.897985', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (42, 'mikhail_guseva', 'mikhail.guseva@example.com', 'Михаил', 'Гусев', '2025-06-13 17:08:40.322059', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (43, 'tatyana_vasiliev', 'tatyana.vasiliev@example.com', 'Татьяна', 'Васильева', '2025-06-13 17:09:07.038348', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (45, 'irina_frolov', 'irina.frolov@example.com', 'Ирина', 'Фролова', '2025-06-13 17:09:07.038348', 2);
INSERT INTO "user".users (user_id, username, email, first_name, last_name, updated_at, role_id) VALUES (47, 'julia_romanov', 'julia.romanov@example.com', 'Юлия', 'Романова', '2025-06-13 17:09:07.038348', 2);


--
-- TOC entry 5347 (class 0 OID 0)
-- Dependencies: 239
-- Name: course_topics_topic_id_seq; Type: SEQUENCE SET; Schema: course; Owner: postgres
--

SELECT pg_catalog.setval('course.course_topics_topic_id_seq', 2, true);


--
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 237
-- Name: courses_course_id_seq; Type: SEQUENCE SET; Schema: course; Owner: postgres
--

SELECT pg_catalog.setval('course.courses_course_id_seq', 50, true);


--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 223
-- Name: finance_categories_category_id_seq; Type: SEQUENCE SET; Schema: finance; Owner: postgres
--

SELECT pg_catalog.setval('finance.finance_categories_category_id_seq', 122, true);


--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 225
-- Name: finances_finance_id_seq; Type: SEQUENCE SET; Schema: finance; Owner: postgres
--

SELECT pg_catalog.setval('finance.finances_finance_id_seq', 214, true);


--
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 231
-- Name: habit_categories_category_id_seq; Type: SEQUENCE SET; Schema: habits; Owner: postgres
--

SELECT pg_catalog.setval('habits.habit_categories_category_id_seq', 15, true);


--
-- TOC entry 5352 (class 0 OID 0)
-- Dependencies: 235
-- Name: habit_logs_log_id_seq; Type: SEQUENCE SET; Schema: habits; Owner: postgres
--

SELECT pg_catalog.setval('habits.habit_logs_log_id_seq', 15, true);


--
-- TOC entry 5353 (class 0 OID 0)
-- Dependencies: 233
-- Name: habits_habit_id_seq; Type: SEQUENCE SET; Schema: habits; Owner: postgres
--

SELECT pg_catalog.setval('habits.habits_habit_id_seq', 15, true);


--
-- TOC entry 5354 (class 0 OID 0)
-- Dependencies: 227
-- Name: todo_categories_category_id_seq; Type: SEQUENCE SET; Schema: todo; Owner: postgres
--

SELECT pg_catalog.setval('todo.todo_categories_category_id_seq', 15, true);


--
-- TOC entry 5355 (class 0 OID 0)
-- Dependencies: 229
-- Name: todos_todo_id_seq; Type: SEQUENCE SET; Schema: todo; Owner: postgres
--

SELECT pg_catalog.setval('todo.todos_todo_id_seq', 15, true);


--
-- TOC entry 5356 (class 0 OID 0)
-- Dependencies: 258
-- Name: expense_categories_category_id_seq; Type: SEQUENCE SET; Schema: trips; Owner: postgres
--

SELECT pg_catalog.setval('trips.expense_categories_category_id_seq', 15, true);


--
-- TOC entry 5357 (class 0 OID 0)
-- Dependencies: 246
-- Name: trip_expenses_expense_id_seq; Type: SEQUENCE SET; Schema: trips; Owner: postgres
--

SELECT pg_catalog.setval('trips.trip_expenses_expense_id_seq', 15, true);


--
-- TOC entry 5358 (class 0 OID 0)
-- Dependencies: 243
-- Name: trip_routes_route_id_seq; Type: SEQUENCE SET; Schema: trips; Owner: postgres
--

SELECT pg_catalog.setval('trips.trip_routes_route_id_seq', 15, true);


--
-- TOC entry 5359 (class 0 OID 0)
-- Dependencies: 241
-- Name: trips_trip_id_seq; Type: SEQUENCE SET; Schema: trips; Owner: postgres
--

SELECT pg_catalog.setval('trips.trips_trip_id_seq', 15, true);


--
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 221
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: user; Owner: postgres
--

SELECT pg_catalog.setval('"user".users_user_id_seq', 5, true);


--
-- TOC entry 4935 (class 2606 OID 27699)
-- Name: course_statuses course_statuses_pkey; Type: CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.course_statuses
    ADD CONSTRAINT course_statuses_pkey PRIMARY KEY (status_id);


--
-- TOC entry 4913 (class 2606 OID 26816)
-- Name: course_topics course_topics_pkey; Type: CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.course_topics
    ADD CONSTRAINT course_topics_pkey PRIMARY KEY (topic_id);


--
-- TOC entry 4908 (class 2606 OID 26801)
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (course_id);


--
-- TOC entry 4910 (class 2606 OID 26921)
-- Name: courses courses_unique; Type: CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.courses
    ADD CONSTRAINT courses_unique UNIQUE (user_id, title);


--
-- TOC entry 4874 (class 2606 OID 26518)
-- Name: finance_categories finance_categories_pkey; Type: CONSTRAINT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finance_categories
    ADD CONSTRAINT finance_categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4929 (class 2606 OID 27226)
-- Name: finance_types finance_types_pkey; Type: CONSTRAINT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finance_types
    ADD CONSTRAINT finance_types_pkey PRIMARY KEY (type_id);


--
-- TOC entry 4876 (class 2606 OID 26535)
-- Name: finances finances_pkey; Type: CONSTRAINT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finances
    ADD CONSTRAINT finances_pkey PRIMARY KEY (finance_id);


--
-- TOC entry 4891 (class 2606 OID 26716)
-- Name: habit_categories habit_categories_pkey; Type: CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_categories
    ADD CONSTRAINT habit_categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4893 (class 2606 OID 26718)
-- Name: habit_categories habit_categories_unique; Type: CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_categories
    ADD CONSTRAINT habit_categories_unique UNIQUE (user_id, name);


--
-- TOC entry 4941 (class 2606 OID 27723)
-- Name: habit_frequencies habit_frequencies_pkey; Type: CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_frequencies
    ADD CONSTRAINT habit_frequencies_pkey PRIMARY KEY (frequency_id);


--
-- TOC entry 4901 (class 2606 OID 26752)
-- Name: habit_logs habit_logs_pkey; Type: CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_logs
    ADD CONSTRAINT habit_logs_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4896 (class 2606 OID 26732)
-- Name: habits habits_pkey; Type: CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habits
    ADD CONSTRAINT habits_pkey PRIMARY KEY (habit_id);


--
-- TOC entry 4898 (class 2606 OID 26923)
-- Name: habits habits_unique; Type: CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habits
    ADD CONSTRAINT habits_unique UNIQUE (user_id, name);


--
-- TOC entry 4906 (class 2606 OID 26754)
-- Name: habit_logs unique_habit_log; Type: CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_logs
    ADD CONSTRAINT unique_habit_log UNIQUE (habit_id, log_date);


--
-- TOC entry 4933 (class 2606 OID 27691)
-- Name: task_priorities task_priorities_pkey; Type: CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.task_priorities
    ADD CONSTRAINT task_priorities_pkey PRIMARY KEY (priority_id);


--
-- TOC entry 4931 (class 2606 OID 27683)
-- Name: task_statuses task_statuses_pkey; Type: CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.task_statuses
    ADD CONSTRAINT task_statuses_pkey PRIMARY KEY (status_id);


--
-- TOC entry 4881 (class 2606 OID 26680)
-- Name: todo_categories todo_categories_pkey; Type: CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todo_categories
    ADD CONSTRAINT todo_categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4887 (class 2606 OID 26697)
-- Name: todos todos_pkey; Type: CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todos
    ADD CONSTRAINT todos_pkey PRIMARY KEY (todo_id);


--
-- TOC entry 4889 (class 2606 OID 27782)
-- Name: todos todos_unique; Type: CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todos
    ADD CONSTRAINT todos_unique UNIQUE (user_id, category_id, task);


--
-- TOC entry 4939 (class 2606 OID 27715)
-- Name: expense_categories expense_categories_pkey; Type: CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.expense_categories
    ADD CONSTRAINT expense_categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4937 (class 2606 OID 27707)
-- Name: transportation_types transportation_types_pkey; Type: CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.transportation_types
    ADD CONSTRAINT transportation_types_pkey PRIMARY KEY (type_id);


--
-- TOC entry 4927 (class 2606 OID 26887)
-- Name: trip_expenses trip_expenses_pkey; Type: CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_expenses
    ADD CONSTRAINT trip_expenses_pkey PRIMARY KEY (expense_id);


--
-- TOC entry 4922 (class 2606 OID 26865)
-- Name: trip_routes trip_routes_pkey; Type: CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_routes
    ADD CONSTRAINT trip_routes_pkey PRIMARY KEY (route_id);


--
-- TOC entry 4919 (class 2606 OID 26852)
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (trip_id);


--
-- TOC entry 4924 (class 2606 OID 26867)
-- Name: trip_routes unique_route_order; Type: CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_routes
    ADD CONSTRAINT unique_route_order UNIQUE (trip_id, location_order);


--
-- TOC entry 4943 (class 2606 OID 27731)
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: user; Owner: postgres
--

ALTER TABLE ONLY "user".user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 4868 (class 2606 OID 26510)
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: user; Owner: postgres
--

ALTER TABLE ONLY "user".users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- TOC entry 4870 (class 2606 OID 26506)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: user; Owner: postgres
--

ALTER TABLE ONLY "user".users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4872 (class 2606 OID 26508)
-- Name: users users_username_unique; Type: CONSTRAINT; Schema: user; Owner: postgres
--

ALTER TABLE ONLY "user".users
    ADD CONSTRAINT users_username_unique UNIQUE (username);


--
-- TOC entry 4914 (class 1259 OID 27774)
-- Name: idx_course_topics_completed_date; Type: INDEX; Schema: course; Owner: postgres
--

CREATE INDEX idx_course_topics_completed_date ON course.course_topics USING btree (completed_date);


--
-- TOC entry 4915 (class 1259 OID 26898)
-- Name: idx_course_topics_course_id; Type: INDEX; Schema: course; Owner: postgres
--

CREATE INDEX idx_course_topics_course_id ON course.course_topics USING btree (course_id);


--
-- TOC entry 4916 (class 1259 OID 27822)
-- Name: idx_course_topics_grade; Type: INDEX; Schema: course; Owner: postgres
--

CREATE INDEX idx_course_topics_grade ON course.course_topics USING btree (grade);


--
-- TOC entry 4911 (class 1259 OID 26917)
-- Name: idx_courses_user_id; Type: INDEX; Schema: course; Owner: postgres
--

CREATE INDEX idx_courses_user_id ON course.courses USING btree (user_id);


--
-- TOC entry 4877 (class 1259 OID 26894)
-- Name: idx_finances_transaction_date; Type: INDEX; Schema: finance; Owner: postgres
--

CREATE INDEX idx_finances_transaction_date ON finance.finances USING btree (transaction_date);


--
-- TOC entry 4878 (class 1259 OID 26893)
-- Name: idx_finances_user_id; Type: INDEX; Schema: finance; Owner: postgres
--

CREATE INDEX idx_finances_user_id ON finance.finances USING btree (user_id);


--
-- TOC entry 4894 (class 1259 OID 26981)
-- Name: idx_habit_categories_user_id; Type: INDEX; Schema: habits; Owner: postgres
--

CREATE INDEX idx_habit_categories_user_id ON habits.habit_categories USING btree (user_id);


--
-- TOC entry 4902 (class 1259 OID 26897)
-- Name: idx_habit_logs_habit_id; Type: INDEX; Schema: habits; Owner: postgres
--

CREATE INDEX idx_habit_logs_habit_id ON habits.habit_logs USING btree (habit_id);


--
-- TOC entry 4903 (class 1259 OID 27780)
-- Name: idx_habit_logs_is_completed; Type: INDEX; Schema: habits; Owner: postgres
--

CREATE INDEX idx_habit_logs_is_completed ON habits.habit_logs USING btree (is_completed);


--
-- TOC entry 4904 (class 1259 OID 26919)
-- Name: idx_habit_logs_log_date; Type: INDEX; Schema: habits; Owner: postgres
--

CREATE INDEX idx_habit_logs_log_date ON habits.habit_logs USING btree (log_date);


--
-- TOC entry 4899 (class 1259 OID 26918)
-- Name: idx_habits_user_id; Type: INDEX; Schema: habits; Owner: postgres
--

CREATE INDEX idx_habits_user_id ON habits.habits USING btree (user_id);


--
-- TOC entry 4879 (class 1259 OID 26980)
-- Name: idx_todo_categories_user_id; Type: INDEX; Schema: todo; Owner: postgres
--

CREATE INDEX idx_todo_categories_user_id ON todo.todo_categories USING btree (user_id);


--
-- TOC entry 4882 (class 1259 OID 27773)
-- Name: idx_todos_completed_date; Type: INDEX; Schema: todo; Owner: postgres
--

CREATE INDEX idx_todos_completed_date ON todo.todos USING btree (completed_date);


--
-- TOC entry 4883 (class 1259 OID 26896)
-- Name: idx_todos_due_date; Type: INDEX; Schema: todo; Owner: postgres
--

CREATE INDEX idx_todos_due_date ON todo.todos USING btree (due_date);


--
-- TOC entry 4884 (class 1259 OID 27772)
-- Name: idx_todos_is_completed; Type: INDEX; Schema: todo; Owner: postgres
--

CREATE INDEX idx_todos_is_completed ON todo.todos USING btree (is_completed);


--
-- TOC entry 4885 (class 1259 OID 26895)
-- Name: idx_todos_user_id; Type: INDEX; Schema: todo; Owner: postgres
--

CREATE INDEX idx_todos_user_id ON todo.todos USING btree (user_id);


--
-- TOC entry 4925 (class 1259 OID 26916)
-- Name: idx_trip_expenses_route_id; Type: INDEX; Schema: trips; Owner: postgres
--

CREATE INDEX idx_trip_expenses_route_id ON trips.trip_expenses USING btree (route_id);


--
-- TOC entry 4920 (class 1259 OID 26915)
-- Name: idx_trip_routes_trip_id; Type: INDEX; Schema: trips; Owner: postgres
--

CREATE INDEX idx_trip_routes_trip_id ON trips.trip_routes USING btree (trip_id);


--
-- TOC entry 4917 (class 1259 OID 26979)
-- Name: idx_trips_user_id; Type: INDEX; Schema: trips; Owner: postgres
--

CREATE INDEX idx_trips_user_id ON trips.trips USING btree (user_id);


--
-- TOC entry 4866 (class 1259 OID 26977)
-- Name: idx_users_user_id; Type: INDEX; Schema: user; Owner: postgres
--

CREATE INDEX idx_users_user_id ON "user".users USING btree (user_id);


--
-- TOC entry 4978 (class 2620 OID 28730)
-- Name: course_topics course_topics_status_trigger; Type: TRIGGER; Schema: course; Owner: postgres
--

CREATE TRIGGER course_topics_status_trigger AFTER INSERT OR UPDATE OF completed_date ON course.course_topics FOR EACH ROW EXECUTE FUNCTION course.update_course_status();


--
-- TOC entry 4979 (class 2620 OID 26957)
-- Name: course_topics course_topics_updated_at_trigger; Type: TRIGGER; Schema: course; Owner: postgres
--

CREATE TRIGGER course_topics_updated_at_trigger BEFORE UPDATE ON course.course_topics FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4977 (class 2620 OID 26954)
-- Name: courses courses_updated_at_trigger; Type: TRIGGER; Schema: course; Owner: postgres
--

CREATE TRIGGER courses_updated_at_trigger BEFORE UPDATE ON course.courses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4968 (class 2620 OID 26930)
-- Name: finance_categories finance_categories_updated_at_trigger; Type: TRIGGER; Schema: finance; Owner: postgres
--

CREATE TRIGGER finance_categories_updated_at_trigger BEFORE UPDATE ON finance.finance_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4969 (class 2620 OID 27771)
-- Name: finances finances_amount_trigger; Type: TRIGGER; Schema: finance; Owner: postgres
--

CREATE TRIGGER finances_amount_trigger BEFORE INSERT OR UPDATE ON finance.finances FOR EACH ROW EXECUTE FUNCTION finance.check_finance_amount();


--
-- TOC entry 4970 (class 2620 OID 26933)
-- Name: finances finances_updated_at_trigger; Type: TRIGGER; Schema: finance; Owner: postgres
--

CREATE TRIGGER finances_updated_at_trigger BEFORE UPDATE ON finance.finances FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4974 (class 2620 OID 26945)
-- Name: habit_categories habit_categories_updated_at_trigger; Type: TRIGGER; Schema: habits; Owner: postgres
--

CREATE TRIGGER habit_categories_updated_at_trigger BEFORE UPDATE ON habits.habit_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4976 (class 2620 OID 26951)
-- Name: habit_logs habit_logs_updated_at_trigger; Type: TRIGGER; Schema: habits; Owner: postgres
--

CREATE TRIGGER habit_logs_updated_at_trigger BEFORE UPDATE ON habits.habit_logs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4975 (class 2620 OID 26948)
-- Name: habits habits_updated_at_trigger; Type: TRIGGER; Schema: habits; Owner: postgres
--

CREATE TRIGGER habits_updated_at_trigger BEFORE UPDATE ON habits.habits FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4971 (class 2620 OID 26939)
-- Name: todo_categories todo_categories_updated_at_trigger; Type: TRIGGER; Schema: todo; Owner: postgres
--

CREATE TRIGGER todo_categories_updated_at_trigger BEFORE UPDATE ON todo.todo_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4972 (class 2620 OID 26709)
-- Name: todos todos_completed_date_trigger; Type: TRIGGER; Schema: todo; Owner: postgres
--

CREATE TRIGGER todos_completed_date_trigger BEFORE UPDATE ON todo.todos FOR EACH ROW EXECUTE FUNCTION todo.set_completed_date();


--
-- TOC entry 4973 (class 2620 OID 26942)
-- Name: todos todos_updated_at_trigger; Type: TRIGGER; Schema: todo; Owner: postgres
--

CREATE TRIGGER todos_updated_at_trigger BEFORE UPDATE ON todo.todos FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4982 (class 2620 OID 26966)
-- Name: trip_expenses trip_expenses_updated_at_trigger; Type: TRIGGER; Schema: trips; Owner: postgres
--

CREATE TRIGGER trip_expenses_updated_at_trigger BEFORE UPDATE ON trips.trip_expenses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4981 (class 2620 OID 26963)
-- Name: trip_routes trip_routes_updated_at_trigger; Type: TRIGGER; Schema: trips; Owner: postgres
--

CREATE TRIGGER trip_routes_updated_at_trigger BEFORE UPDATE ON trips.trip_routes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4980 (class 2620 OID 26960)
-- Name: trips trips_updated_at_trigger; Type: TRIGGER; Schema: trips; Owner: postgres
--

CREATE TRIGGER trips_updated_at_trigger BEFORE UPDATE ON trips.trips FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4967 (class 2620 OID 26927)
-- Name: users users_updated_at_trigger; Type: TRIGGER; Schema: user; Owner: postgres
--

CREATE TRIGGER users_updated_at_trigger BEFORE UPDATE ON "user".users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4960 (class 2606 OID 27059)
-- Name: course_topics course_topics_course_id_fkey; Type: FK CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.course_topics
    ADD CONSTRAINT course_topics_course_id_fkey FOREIGN KEY (course_id) REFERENCES course.courses(course_id) ON DELETE CASCADE;


--
-- TOC entry 4961 (class 2606 OID 27054)
-- Name: course_topics course_topics_user_id_fkey; Type: FK CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.course_topics
    ADD CONSTRAINT course_topics_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4958 (class 2606 OID 27049)
-- Name: courses courses_user_id_fkey; Type: FK CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.courses
    ADD CONSTRAINT courses_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4959 (class 2606 OID 27739)
-- Name: courses fk_courses_status; Type: FK CONSTRAINT; Schema: course; Owner: postgres
--

ALTER TABLE ONLY course.courses
    ADD CONSTRAINT fk_courses_status FOREIGN KEY (status_id) REFERENCES course.course_statuses(status_id);


--
-- TOC entry 4945 (class 2606 OID 26994)
-- Name: finance_categories finance_categories_user_id_fkey; Type: FK CONSTRAINT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finance_categories
    ADD CONSTRAINT finance_categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4947 (class 2606 OID 27004)
-- Name: finances finances_category_id_fkey; Type: FK CONSTRAINT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finances
    ADD CONSTRAINT finances_category_id_fkey FOREIGN KEY (category_id) REFERENCES finance.finance_categories(category_id) ON DELETE CASCADE;


--
-- TOC entry 4948 (class 2606 OID 26999)
-- Name: finances finances_user_id_fkey; Type: FK CONSTRAINT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finances
    ADD CONSTRAINT finances_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4946 (class 2606 OID 27229)
-- Name: finance_categories fk_finance_categories_type; Type: FK CONSTRAINT; Schema: finance; Owner: postgres
--

ALTER TABLE ONLY finance.finance_categories
    ADD CONSTRAINT fk_finance_categories_type FOREIGN KEY (type_id) REFERENCES finance.finance_types(type_id);


--
-- TOC entry 4954 (class 2606 OID 27759)
-- Name: habits fk_habits_frequency; Type: FK CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habits
    ADD CONSTRAINT fk_habits_frequency FOREIGN KEY (frequency_id) REFERENCES habits.habit_frequencies(frequency_id);


--
-- TOC entry 4953 (class 2606 OID 27029)
-- Name: habit_categories habit_categories_user_id_fkey; Type: FK CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_categories
    ADD CONSTRAINT habit_categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4957 (class 2606 OID 27044)
-- Name: habit_logs habit_logs_habit_id_fkey; Type: FK CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habit_logs
    ADD CONSTRAINT habit_logs_habit_id_fkey FOREIGN KEY (habit_id) REFERENCES habits.habits(habit_id) ON DELETE CASCADE;


--
-- TOC entry 4955 (class 2606 OID 27039)
-- Name: habits habits_category_id_fkey; Type: FK CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habits
    ADD CONSTRAINT habits_category_id_fkey FOREIGN KEY (category_id) REFERENCES habits.habit_categories(category_id) ON DELETE CASCADE;


--
-- TOC entry 4956 (class 2606 OID 27034)
-- Name: habits habits_user_id_fkey; Type: FK CONSTRAINT; Schema: habits; Owner: postgres
--

ALTER TABLE ONLY habits.habits
    ADD CONSTRAINT habits_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4950 (class 2606 OID 27734)
-- Name: todos fk_todos_task_priority; Type: FK CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todos
    ADD CONSTRAINT fk_todos_task_priority FOREIGN KEY (task_priority_id) REFERENCES todo.task_priorities(priority_id);


--
-- TOC entry 4949 (class 2606 OID 27014)
-- Name: todo_categories todo_categories_user_id_fkey; Type: FK CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todo_categories
    ADD CONSTRAINT todo_categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4951 (class 2606 OID 27024)
-- Name: todos todos_category_id_fkey; Type: FK CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todos
    ADD CONSTRAINT todos_category_id_fkey FOREIGN KEY (category_id) REFERENCES todo.todo_categories(category_id) ON DELETE CASCADE;


--
-- TOC entry 4952 (class 2606 OID 27019)
-- Name: todos todos_user_id_fkey; Type: FK CONSTRAINT; Schema: todo; Owner: postgres
--

ALTER TABLE ONLY todo.todos
    ADD CONSTRAINT todos_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4965 (class 2606 OID 27754)
-- Name: trip_expenses fk_trip_expenses_category; Type: FK CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_expenses
    ADD CONSTRAINT fk_trip_expenses_category FOREIGN KEY (expense_category_id) REFERENCES trips.expense_categories(category_id);


--
-- TOC entry 4963 (class 2606 OID 27749)
-- Name: trip_routes fk_trip_routes_transportation_type; Type: FK CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_routes
    ADD CONSTRAINT fk_trip_routes_transportation_type FOREIGN KEY (transportation_type_id) REFERENCES trips.transportation_types(type_id);


--
-- TOC entry 4966 (class 2606 OID 27074)
-- Name: trip_expenses trip_expenses_route_id_fkey; Type: FK CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_expenses
    ADD CONSTRAINT trip_expenses_route_id_fkey FOREIGN KEY (route_id) REFERENCES trips.trip_routes(route_id) ON DELETE CASCADE;


--
-- TOC entry 4964 (class 2606 OID 27069)
-- Name: trip_routes trip_routes_trip_id_fkey; Type: FK CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trip_routes
    ADD CONSTRAINT trip_routes_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES trips.trips(trip_id) ON DELETE CASCADE;


--
-- TOC entry 4962 (class 2606 OID 27064)
-- Name: trips trips_user_id_fkey; Type: FK CONSTRAINT; Schema: trips; Owner: postgres
--

ALTER TABLE ONLY trips.trips
    ADD CONSTRAINT trips_user_id_fkey FOREIGN KEY (user_id) REFERENCES "user".users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4944 (class 2606 OID 27765)
-- Name: users fk_users_role; Type: FK CONSTRAINT; Schema: user; Owner: postgres
--

ALTER TABLE ONLY "user".users
    ADD CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES "user".user_roles(role_id);


-- Completed on 2025-06-29 15:04:56

--
-- PostgreSQL database dump complete
--

