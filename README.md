# jobsearch_tracking_db
A DuckDB database for tracking applications placed as part of a job search.

** A note about foreign keys **
The initial version of the database included foreign key definitions linking tables like Applications.resume_id to Resume.id, etc. However, those have been removed from my working version of the db and commented out in this creation script because [DuckDB, as of 0.9.2, has a known issue with constraints](https://duckdb.org/docs/sql/indexes#over-eager-unique-constraint-checking) which prevented me from being able to update Application records when and ApplicationEvent record referenced them. 

## DB structure

### Entities
The database tracks four primary entities: Applications, ApplicationEvents, EventTypes, and Resumes. Entities are named using an upper-camel-case syntax.

#### Applications
The Applications table records an instance of an application to a job listing.

#### ApplicationEvents
ApplicationEvents are outcomes of an Application, such as a Follow-up call back for an interview or a Rejection.

#### EventTypes
EventTypes define the kinds of events which are tracked in the ApplicationEvents.

#### Resumes
Resumes track versions of your resume, allowing you to indicate which version was sent to a particular position opening and create response conversion rates to see the effectiveness of changes to your resume over time.

### Views
Views have been created to provide non-relational insights. Views are named using a lower-camel-case syntax.

#### applicationStatus
The applicationStatus view lists information about the position as well as the most recent ApplicationEvent associated with the Application.

#### latestStatus
The latestStatus view is primarily a helper view for the de-normalized applicationStatus view.

#### resumeConversionRate
The resumeConversionRate view lists each resume version, the number of Applications using that resume version, and the number of those applications which have converted, that is, received at least one Follow-Up event.
