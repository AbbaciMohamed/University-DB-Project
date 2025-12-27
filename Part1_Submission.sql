--
-- PostgreSQL database dump
--

\restrict Jsh6Kd5najeGPH5ZcRZneurxSejUJAGnaDz80R0oLFGGJ1rv9ux25UieELeCPGW

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2025-12-27 19:38:44

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5120 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 232 (class 1255 OID 17516)
-- Name: calculate(real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate(t real) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT $1 * 0.06; -- $1 refers to the 't' parameter
$_$;


ALTER FUNCTION public.calculate(t real) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 18294)
-- Name: check_reservation_conflict(text, text, date, time without time zone, time without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_reservation_conflict(p_building text, p_roomno text, p_res_date date, p_start_time time without time zone, p_end_time time without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflict_id INTEGER;
BEGIN
    -- 1. Use the optimized OVERLAPS check to find ONE conflicting reservation ID
    SELECT 
        reservation_id INTO conflict_id
    FROM 
        Reservation R
    WHERE
        -- Match Room and Date
        R.building = p_building
        AND R.roomno = p_roomno
        AND R.reserv_date = p_res_date
        -- Check for time conflict using the OVERLAPS operator
        AND (R.start_time, R.end_time) OVERLAPS (p_start_time, p_end_time)
    LIMIT 1; -- We only need one ID to confirm a conflict exists

    -- 2. Return the conflicting ID, or 0 if no conflict was found
    IF conflict_id IS NOT NULL THEN
        RETURN conflict_id; -- Conflict found, return the ID
    ELSE
        RETURN 0;           -- No conflict
    END IF;
END;
$$;


ALTER FUNCTION public.check_reservation_conflict(p_building text, p_roomno text, p_res_date date, p_start_time time without time zone, p_end_time time without time zone) OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 18295)
-- Name: get_all_reservation_conflicts(text, text, date, time without time zone, time without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_all_reservation_conflicts(p_building text, p_roomno text, p_res_date date, p_start_time time without time zone, p_end_time time without time zone) RETURNS SETOF integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        reservation_id
    FROM 
        Reservation R
    WHERE
        R.building = p_building
        AND R.roomno = p_roomno
        AND R.reserv_date = p_res_date
        -- Check for time conflict using the OVERLAPS operator
        AND (R.start_time, R.end_time) OVERLAPS (p_start_time, p_end_time);
    -- NO LIMIT 1 here
END;
$$;


ALTER FUNCTION public.get_all_reservation_conflicts(p_building text, p_roomno text, p_res_date date, p_start_time time without time zone, p_end_time time without time zone) OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 18119)
-- Name: get_department_id_by_name(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_department_id_by_name(dept_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    dept_id_result INT4;
BEGIN
    -- Note: We use the lowercase, unquoted column names as verified in your schema
    SELECT department_id INTO dept_id_result
    FROM Department
    WHERE name = dept_name;

    -- Standard check for errors
    IF dept_id_result IS NULL THEN
        RAISE EXCEPTION 'Department with name % not found.', dept_name;
    END IF;

    RETURN dept_id_result;
END;
$$;


ALTER FUNCTION public.get_department_id_by_name(dept_name character varying) OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 18292)
-- Name: get_rooms_by_capacity(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_rooms_by_capacity(min_capacity integer) RETURNS TABLE(room_no character varying, building character varying, capacity integer)
    LANGUAGE sql
    AS $$
    SELECT
        roomno, -- Corrected column name
        building, -- Corrected column name
        capacity
    FROM
        Room
    WHERE
        capacity >= min_capacity;
$$;


ALTER FUNCTION public.get_rooms_by_capacity(min_capacity integer) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 18309)
-- Name: log_student_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_student_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- TG_OP holds the type of operation that occurred
    INSERT INTO Student_Audit_Log (operation_type, description)
    VALUES (
        TG_OP, 
        'Operation ' || TG_OP || ' executed on Student table by ' || SESSION_USER || ' at ' || NOW()
    );
    RETURN NULL; -- Must return NULL for an AFTER trigger
END;
$$;


ALTER FUNCTION public.log_student_changes() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 18051)
-- Name: course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course (
    course_id integer NOT NULL,
    department_id integer NOT NULL,
    name character varying(60) NOT NULL,
    description character varying(1000)
);


ALTER TABLE public.course OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 18019)
-- Name: department; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.department (
    department_id integer NOT NULL,
    name character varying(25) NOT NULL
);


ALTER TABLE public.department OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 18237)
-- Name: enrollment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enrollment (
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    department_id integer NOT NULL,
    enrollment_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE public.enrollment OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 18066)
-- Name: instructor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instructor (
    instructor_id integer NOT NULL,
    department_id integer NOT NULL,
    last_name character varying(25) NOT NULL,
    first_name character varying(25) NOT NULL,
    rank character varying(25),
    phone character varying(15) DEFAULT NULL::character varying,
    fax character varying(15) DEFAULT NULL::character varying,
    email character varying(100) DEFAULT NULL::character varying,
    CONSTRAINT ck_instructor_rank CHECK (((rank)::text = ANY ((ARRAY['Substitute'::character varying, 'MCB'::character varying, 'MCA'::character varying, 'PROF'::character varying])::text[])))
);


ALTER TABLE public.instructor OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 18084)
-- Name: reservation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservation (
    reservation_id integer NOT NULL,
    building character varying(1) NOT NULL,
    roomno character varying(20) NOT NULL,
    course_id integer NOT NULL,
    department_id integer NOT NULL,
    instructor_id integer NOT NULL,
    reserv_date date DEFAULT CURRENT_DATE NOT NULL,
    start_time time without time zone DEFAULT CURRENT_TIME NOT NULL,
    end_time time without time zone DEFAULT '23:00:00'::time without time zone NOT NULL,
    hours_number integer NOT NULL,
    CONSTRAINT ck_reservation_hours_number CHECK ((hours_number >= 1)),
    CONSTRAINT ck_reservation_startendtime CHECK ((start_time < end_time))
);


ALTER TABLE public.reservation OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 18279)
-- Name: instructor_reservation_count; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.instructor_reservation_count AS
 SELECT i.instructor_id,
    i.first_name,
    i.last_name,
    count(r.reservation_id) AS total_reservations
   FROM (public.instructor i
     LEFT JOIN public.reservation r ON ((i.instructor_id = r.instructor_id)))
  GROUP BY i.instructor_id, i.first_name, i.last_name
  ORDER BY (count(r.reservation_id)) DESC;


ALTER VIEW public.instructor_reservation_count OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 18284)
-- Name: instructor_reservation_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.instructor_reservation_mv AS
 SELECT instructor_id,
    first_name,
    last_name,
    total_reservations
   FROM public.instructor_reservation_count
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.instructor_reservation_mv OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 18258)
-- Name: marks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.marks (
    mark_id integer NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    department_id integer NOT NULL,
    mark_value numeric(5,2) NOT NULL,
    mark_type character varying(50)
);


ALTER TABLE public.marks OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 18257)
-- Name: marks_mark_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.marks_mark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.marks_mark_id_seq OWNER TO postgres;

--
-- TOC entry 5121 (class 0 OID 0)
-- Dependencies: 226
-- Name: marks_mark_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.marks_mark_id_seq OWNED BY public.marks.mark_id;


--
-- TOC entry 221 (class 1259 OID 18043)
-- Name: room; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.room (
    building character varying(1) NOT NULL,
    roomno character varying(20) NOT NULL,
    capacity integer,
    CONSTRAINT room_capacity_check CHECK ((capacity > 1))
);


ALTER TABLE public.room OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 18028)
-- Name: student; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student (
    student_id integer NOT NULL,
    last_name character varying(25) NOT NULL,
    first_name character varying(25) NOT NULL,
    dob date NOT NULL,
    address character varying(50) DEFAULT NULL::character varying,
    city character varying(25) DEFAULT NULL::character varying,
    zip_code character varying(9) DEFAULT NULL::character varying,
    phone character varying(15) DEFAULT NULL::character varying,
    fax character varying(15) DEFAULT NULL::character varying,
    email character varying(100) DEFAULT NULL::character varying
);


ALTER TABLE public.student OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 18297)
-- Name: student_audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_audit_log (
    audit_id integer NOT NULL,
    operation_type character varying(10) NOT NULL,
    audit_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    changed_by character varying(50) DEFAULT SESSION_USER,
    description text
);


ALTER TABLE public.student_audit_log OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 18296)
-- Name: student_audit_log_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_audit_log_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_audit_log_audit_id_seq OWNER TO postgres;

--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 230
-- Name: student_audit_log_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_audit_log_audit_id_seq OWNED BY public.student_audit_log.audit_id;


--
-- TOC entry 4916 (class 2604 OID 18261)
-- Name: marks mark_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.marks ALTER COLUMN mark_id SET DEFAULT nextval('public.marks_mark_id_seq'::regclass);


--
-- TOC entry 4917 (class 2604 OID 18300)
-- Name: student_audit_log audit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_audit_log ALTER COLUMN audit_id SET DEFAULT nextval('public.student_audit_log_audit_id_seq'::regclass);


--
-- TOC entry 5106 (class 0 OID 18051)
-- Dependencies: 222
-- Data for Name: course; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.course VALUES (1, 1, 'Databases', 'Licence(L3) : Modeling E/A and UML, Relational Model, Relational Algebra, Relational calculs,SQL, NFs and FDs');
INSERT INTO public.course VALUES (2, 1, 'C++ progr.', 'Level Master 1');
INSERT INTO public.course VALUES (3, 1, 'Advanced DBs', 'Level Master 2 -Program Licence and Master 1');
INSERT INTO public.course VALUES (4, 4, 'English', '');


--
-- TOC entry 5103 (class 0 OID 18019)
-- Dependencies: 219
-- Data for Name: department; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.department VALUES (1, 'SADS');
INSERT INTO public.department VALUES (2, 'CCS');
INSERT INTO public.department VALUES (3, 'GRC');
INSERT INTO public.department VALUES (4, 'INS');
INSERT INTO public.department VALUES (10, 'DBMS');


--
-- TOC entry 5109 (class 0 OID 18237)
-- Dependencies: 225
-- Data for Name: enrollment; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5107 (class 0 OID 18066)
-- Dependencies: 223
-- Data for Name: instructor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.instructor VALUES (1, 1, 'Abbas', 'BenAbbes', 'MCA', '4185', '4091', 'Ab@yahoo.fr');
INSERT INTO public.instructor VALUES (2, 1, 'Mokhtar', 'BenMokhtar', 'Substitute', NULL, NULL, NULL);
INSERT INTO public.instructor VALUES (3, 1, 'Djemaa', 'Ben Mohamed', 'MCB', NULL, NULL, NULL);
INSERT INTO public.instructor VALUES (4, 1, 'Lahlou', 'Mohamed', 'PROF', NULL, NULL, NULL);
INSERT INTO public.instructor VALUES (5, 1, 'Abla', 'Chad', 'MCA', NULL, NULL, 'ab@lgmail.com');
INSERT INTO public.instructor VALUES (6, 4, 'Mariam', 'BALI', 'Substitute', NULL, NULL, NULL);


--
-- TOC entry 5111 (class 0 OID 18258)
-- Dependencies: 227
-- Data for Name: marks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5108 (class 0 OID 18084)
-- Dependencies: 224
-- Data for Name: reservation; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reservation VALUES (1, 'B', '022', 1, 1, 1, '2006-10-15', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (2, 'B', '022', 1, 1, 4, '2006-11-04', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (3, 'B', '022', 1, 1, 4, '2006-11-07', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (4, 'B', '020', 1, 1, 5, '2006-10-20', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (5, 'B', '020', 1, 1, 4, '2006-12-09', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (6, 'A', '301', 2, 1, 1, '2006-09-02', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (7, 'A', '301', 2, 1, 1, '2006-09-03', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (8, 'A', '301', 2, 1, 1, '2006-09-10', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (9, 'A', '301', 3, 1, 1, '2006-09-24', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (10, 'B', '022', 3, 1, 1, '2006-10-15', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (11, 'A', '301', 3, 1, 1, '2006-10-01', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (12, 'A', '301', 3, 1, 1, '2006-10-08', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (13, 'B', '022', 1, 1, 4, '2006-11-03', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (14, 'B', '022', 1, 1, 5, '2006-10-20', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (15, 'B', '022', 1, 1, 4, '2006-12-09', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (16, 'B', '022', 1, 1, 4, '2006-09-03', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (17, 'B', '022', 1, 1, 5, '2006-09-10', '08:30:00', '11:45:00', 3);
INSERT INTO public.reservation VALUES (18, 'B', '022', 1, 1, 4, '2006-09-24', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (19, 'B', '022', 1, 1, 5, '2006-10-01', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (20, 'B', '022', 1, 1, 1, '2006-10-08', '13:45:00', '17:00:00', 3);
INSERT INTO public.reservation VALUES (21, 'B', '022', 1, 1, 4, '2003-09-02', '08:30:00', '11:45:00', 3);


--
-- TOC entry 5105 (class 0 OID 18043)
-- Dependencies: 221
-- Data for Name: room; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.room VALUES ('B', '020', 15);
INSERT INTO public.room VALUES ('B', '022', 15);
INSERT INTO public.room VALUES ('A', '301', 45);
INSERT INTO public.room VALUES ('C', 'Lecture Hall 1', 500);
INSERT INTO public.room VALUES ('C', 'Lecture Hall 2', 200);


--
-- TOC entry 5104 (class 0 OID 18028)
-- Dependencies: 220
-- Data for Name: student; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.student VALUES (1, 'Ali', 'Ben Ali', '1979-02-18', '50, 1st street', 'Algiers', '16000', '0143567890', NULL, 'A1@yahoo.fr');
INSERT INTO public.student VALUES (2, 'Amar', 'Ben Ammar', '1980-08-23', '10, Avenue b', 'BATNA', '05000', '0678567801', NULL, 'pt@yahoo.fr');
INSERT INTO public.student VALUES (3, 'Ameur', 'Ben Ameur', '1978-05-12', '25, 2nd street', 'Oran', '31000', '0145678956', '0145678956', 'o@yahoo.fr');
INSERT INTO public.student VALUES (4, 'Aissa', 'Ben Aissa', '1979-07-15', '56, Road', 'Annaba', '23000', '0678905645', NULL, 'd@hotmail.com');
INSERT INTO public.student VALUES (5, 'Fatima', 'Ben Abdedallah', '1979-08-15', '45, Faubourg', 'Constantine', '25000', NULL, NULL, NULL);


--
-- TOC entry 5114 (class 0 OID 18297)
-- Dependencies: 231
-- Data for Name: student_audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5123 (class 0 OID 0)
-- Dependencies: 226
-- Name: marks_mark_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.marks_mark_id_seq', 1, false);


--
-- TOC entry 5124 (class 0 OID 0)
-- Dependencies: 230
-- Name: student_audit_log_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_audit_log_audit_id_seq', 1, false);


--
-- TOC entry 4941 (class 2606 OID 18268)
-- Name: marks marks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.marks
    ADD CONSTRAINT marks_pkey PRIMARY KEY (mark_id);


--
-- TOC entry 4933 (class 2606 OID 18060)
-- Name: course pk_course; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT pk_course PRIMARY KEY (course_id, department_id);


--
-- TOC entry 4925 (class 2606 OID 18025)
-- Name: department pk_department; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT pk_department PRIMARY KEY (department_id);


--
-- TOC entry 4939 (class 2606 OID 18246)
-- Name: enrollment pk_enrollment; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment
    ADD CONSTRAINT pk_enrollment PRIMARY KEY (student_id, course_id, department_id);


--
-- TOC entry 4935 (class 2606 OID 18078)
-- Name: instructor pk_instructor; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor
    ADD CONSTRAINT pk_instructor PRIMARY KEY (instructor_id);


--
-- TOC entry 4937 (class 2606 OID 18103)
-- Name: reservation pk_reservation; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT pk_reservation PRIMARY KEY (reservation_id);


--
-- TOC entry 4931 (class 2606 OID 18050)
-- Name: room pk_room; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT pk_room PRIMARY KEY (building, roomno);


--
-- TOC entry 4929 (class 2606 OID 18042)
-- Name: student pk_student; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT pk_student PRIMARY KEY (student_id);


--
-- TOC entry 4943 (class 2606 OID 18308)
-- Name: student_audit_log student_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_audit_log
    ADD CONSTRAINT student_audit_log_pkey PRIMARY KEY (audit_id);


--
-- TOC entry 4927 (class 2606 OID 18027)
-- Name: department un_department_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT un_department_name UNIQUE (name);


--
-- TOC entry 4953 (class 2620 OID 18310)
-- Name: student trg_audit_students_statement; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_students_statement AFTER INSERT OR DELETE OR UPDATE ON public.student FOR EACH STATEMENT EXECUTE FUNCTION public.log_student_changes();


--
-- TOC entry 4944 (class 2606 OID 18061)
-- Name: course FK_Course_Department; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT "FK_Course_Department" FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4945 (class 2606 OID 18079)
-- Name: instructor FK_Instructor_Department_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor
    ADD CONSTRAINT "FK_Instructor_Department_ID" FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4946 (class 2606 OID 18109)
-- Name: reservation FK_Reservation_Course; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT "FK_Reservation_Course" FOREIGN KEY (course_id, department_id) REFERENCES public.course(course_id, department_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4947 (class 2606 OID 18114)
-- Name: reservation FK_Reservation_Instructor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT "FK_Reservation_Instructor" FOREIGN KEY (instructor_id) REFERENCES public.instructor(instructor_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4948 (class 2606 OID 18104)
-- Name: reservation FK_Reservation_Room; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT "FK_Reservation_Room" FOREIGN KEY (building, roomno) REFERENCES public.room(building, roomno) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4949 (class 2606 OID 18252)
-- Name: enrollment fk_enroll_course; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment
    ADD CONSTRAINT fk_enroll_course FOREIGN KEY (course_id, department_id) REFERENCES public.course(course_id, department_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4950 (class 2606 OID 18247)
-- Name: enrollment fk_enroll_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollment
    ADD CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES public.student(student_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4951 (class 2606 OID 18274)
-- Name: marks fk_marks_course; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.marks
    ADD CONSTRAINT fk_marks_course FOREIGN KEY (course_id, department_id) REFERENCES public.course(course_id, department_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4952 (class 2606 OID 18269)
-- Name: marks fk_marks_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.marks
    ADD CONSTRAINT fk_marks_student FOREIGN KEY (student_id) REFERENCES public.student(student_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 5112 (class 0 OID 18284)
-- Dependencies: 229 5116
-- Name: instructor_reservation_mv; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.instructor_reservation_mv;


-- Completed on 2025-12-27 19:38:44

--
-- PostgreSQL database dump complete
--

\unrestrict Jsh6Kd5najeGPH5ZcRZneurxSejUJAGnaDz80R0oLFGGJ1rv9ux25UieELeCPGW

