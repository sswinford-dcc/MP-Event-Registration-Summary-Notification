/*********************************************
*** Event Registration Summary Email Setup ***
**********************************************
Version: 1.0
Author: Stephan Swinford
Date: 2/24/2020

This script is provided "as is" with no warranties expressed or implied.

-- Description --
The below script is used to help set up the required Configuration Keys
that are needed for the Event Registration Summary Email Notification.
This script will insert the required Configuration Keys into the 
dp_Configuration_Settings table for you.

*********************************************/

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