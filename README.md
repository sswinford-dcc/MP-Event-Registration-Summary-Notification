A custom Dream City Church procedure for Ministry Platform
Version: 1.0
Author: Stephan Swinford
Date: 2/24/2020

This procedure is provided "as is" with no warranties expressed or implied.

-- Description --
This procedure will send an email summary containing the current count of Participants to the Primary Contact of any upcoming Event that is both a 'public'
Event and also has an active Registration with a Registration Product. The procedure will send summaries weekly on the specified Day of Week, and then daily
for any Event when its Start Date is within the Days Before key value.

-- Requirements --
1) The following 3 Configuration Setting Keys are used within this procedure and allow you to change some of the basic functionality.
   Create these keys under Administration > Configuration Settings before using this procedure, or use the script block below.
	i) 	Application Code: SERVICES
		Key Name: NotificationEventRegistrationsSummaryMessageID
		Value: 
		Description: Specify the Message ID number for the template that you want to use. The template should include the [Event_List] placeholder. Clear value to disable notifications.
		Page Reference: Messages

	ii) Application Code: SERVICES
		Key Name: NotificationEventRegistrationsSummarySendDoW
		Description: The day of the week that you want normal summary notifications to be sent. 1=Sunday, 7=Saturday.
		Value: 2
		Page Reference: NULL

	iii)Application Code: SERVICES
		Key Name: NotificationEventRegistrationsSummaryDaysBefore.
		Description: How many days before an Event Start Date do you want to send daily update notifications.
		Value: 3
		Page Reference: NULL
	
	-- Copy and execute the below script block to have the above key values created for you:
		USE MinistryPlatform;
		GO
		DECLARE @DomainID INT = 1
		,@MessagePageID INT = ISNULL((SELECT TOP 1 Page_ID FROM dp_Pages P WHERE P.Table_Name = 'dp_Communications' AND P.Filter_Clause IS NULL ORDER BY Page_ID),341)
		INSERT INTO dp_Configuration_Settings(Application_Code,Key_Name,Value,Description,Primary_Key_Page_ID,Domain_ID)
			VALUES 
				('SERVICES','NotificationEventRegistrationsSummaryMessageID',NULL,'Event Registration Summary Notification Procdure: Specify the Message ID number for the template that you want to use. The template should include the [Event_List] placeholder. Clear value to disable notifications.',@MessagePageID,@DomainID)
				,('SERVICES','NotificationEventRegistrationsSummarySendDoW',2,'Event Registration Summary Notification Procedure: The day of the week that you want normal summary notifications to be sent. 1=Sunday, 7=Saturday.',NULL,@DomainID)
				,('SERVICES','NotificationEventRegistrationsSummaryDaysBefore',3,'Event Registration Summary Notification Procedure: How many days before an Event Start Date do you want to send daily update notifications.',NULL,@DomainID)
		GO

2) A SQL Server Agent Job that runs daily and calls this procedure needs to be created, or a step needs to be added to an existing daily job.
	-- NOTE: Do not use any of the built-in MinistryPlatform jobs as ThinkMinistry may update those jobs
			 at any time and remove your custom Job Step. Create a new Job with a Daily trigger.

	-- Job Step details:
		Step Name: Event Registrattion Summary Notifications (your choice on name)
		Type: Transact-SQL script (T-SQL)
		Database: MinistryPlatform
		Command: EXEC [dbo].[service_notification_event_registrations_summary] @DomainID = 1
