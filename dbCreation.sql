/* Job Search DB Definition */

create sequence application_id;
create sequence resume_id;
create sequence applicationevent_id;

create or replace table Resumes (
	id integer primary key default nextval('resume_id'),
	name varchar,
	filepath varchar,
	notes varchar
);

create or replace table EventTypes (
	name varchar primary key,
	description varchar,
	is_terminal boolean
);

insert into EventTypes (name, description, is_terminal) values
	('Rejection', 'Company initiated rejection', True),
	('Follow-up', 'Company follow-up for next round of interview/discussion', False),
	('Offer', 'Company extended offer', False),
	('Offer acceptance', 'Applicant accepted offer', True),
	('Offer rejection', 'Applicant rejected offer', True),
	('Application withdrawn', 'Applicant withdrew application', True)
;

create or replace table Applications (
	id integer primary key default nextval('application_id'),
	company_name varchar not null,
	url varchar not null,
	role varchar not null,
	salary_min_usd integer,
	salary_max_usd integer,
	resume_id integer not null,
	application_date date default current_date,

	/* foreign key definitions
	foreign key (resume_id) references Resumes (id)
	*/
);

create or replace table ApplicationEvents (
	id integer primary key default nextval('applicationevent_id'),
	application_id integer not null,
	eventtype_name varchar not null,
	event_date date default current_date,
	notes text,

	/*
	foreign key (application_id) references Applications (id),
	foreign key (eventtype_name) references EventTypes (name)
	*/

);

/* view for each application's current status */
CREATE VIEW latestStatus (application_id, eventtype_name, event_date) AS 
	SELECT application_id, 
		eventtype_name, 
		event_date 
	FROM (
		SELECT application_id, 
			eventtype_name, 
			event_date, 
			rank() OVER (
				PARTITION BY application_id 
				ORDER BY event_date DESC) 
			AS r FROM ApplicationEvents
			) 
	WHERE (r = 1);

/* view for seeing information about an application and its current status */
CREATE VIEW applicationStatus (id, company_name, url, role_trimmed, application_date, response) AS 
	SELECT a.id, 
		company_name, 
		url, 
		left("role", 20) AS role_trimmed, 
		application_date, 
		eventtype_name AS response 
	FROM Applications AS a 
		LEFT JOIN latestStatus AS l 
			ON ((a.id = l.application_id));

/* view for tracking conversion rates of resume types */
create or replace view resumeConversionRate as (
	with conversions as (
		select distinct application_id
		from ApplicationEvents
		where eventtype_name = 'Follow-up'
	),

	application_conversion as (
		select id as application_id, resume_id,
			case when id in (select application_id from conversions) then 1 else 0 end as received_conversion
		from Applications
	)

		select r.id as resume_id, 
			count(application_id) as resume_applications,
			count(*) filter (where received_conversion = 1) as resume_conversions,
			round(resume_conversions / resume_applications, 4) as resume_conversion_rate
		from Resumes as r
			left join application_conversion as ac
			on r.id = ac.resume_id
		group by r.id
);