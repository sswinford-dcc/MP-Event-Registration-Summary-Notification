> # Event Registration Summary Email Notification
> ***A custom Dream City Church procedure for Ministry Platform***
>
> Version: 1.0
>
> Author: Stephan Swinford
>
> Date: 2/24/2020

`This procedure is provided "as is" with no warranties expressed or implied.`

**Description**

This procedure will send a summary email to an Event's Primary Contact with the current count of Participants. To receive the notification, the Contact should have a valid email address and the Event should be both 'public' and also have an active Registration with a Registration Product. The procedure will send summaries weekly on the specified Day of Week, and then daily for any Event when its Start Date is within the Days Before key value.

**Requirements**

 1. The following 3 Configuration Setting Keys are used within this procedure and allow you to change some of the basic functionality. Create these keys under Administration > Configuration Settings before using this procedure, or use service_notification_event_registrations_setup.sql
    * NotificationEventRegistrationsSummaryMessageID
    * NotificationEventRegistrationsSummarySendDoW
    * NotificationEventRegistrationsSummaryDaysBefore.

2. A SQL Server Agent Job that runs daily and calls this procedure needs to be created, or a step needs to be added to an existing daily job.
    * NOTE: Do not use any of the built-in MinistryPlatform jobs as ThinkMinistry may update those jobs at any time and remove your custom Job Step. Create a new Job with a Daily trigger.
    * Job Step details:
      **Step Name:** Event Registration Summary Notifications (*your choice on name*)
      **Type:** Transact-SQL script (T-SQL)
      **Database:** MinistryPlatform
      **Command:** EXEC [dbo].[service_notification_event_registrations_summary] @DomainID = 1
      
**Installation**
1. Run [event_registration_summary_email_setup.sql](event_registration_summary_email_setup.sql) to install the required Configuration Setting Keys into your database.
2. Run [service_notification_event_registrations_summary.sql](service_notification_event_registrations_summary.sql) to install the procedure onto your SQL server.
3. Modify the values for the 3 Configuration Setting Keys. The values must only contain a single integer.
4. Add a Job Step to a SQL Agent Job that has a daily trigger. See Requirement 2 for more information.
