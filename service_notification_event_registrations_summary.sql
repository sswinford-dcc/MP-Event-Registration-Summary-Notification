USE [MinistryPlatform]
GO
/****** Object:  StoredProcedure [dbo].[service_notification_event_registrations_summary]    Script Date: 2/24/2020 1:22:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[service_notification_event_registrations_summary]

	@DomainID INT

AS

/****************************************************
*** Event Registration Summary Email Notification ***
*****************************************************
A custom Dream City Church procedure for Ministry Platform
Version: 1.0
Author: Stephan Swinford
Date: 2/24/2020

This procedure is provided "as is" with no warranties expressed or implied.

-- Description --
This procedure will send a summary email to an Event's Primary Contact with
the current count of Participants. To receive the notification, the Contact
should have a valid email address and the Event should be both 'public' and
also have an active Registration with a Registration Product. The procedure
will send summaries weekly on the specified Day of Week, and then daily for
any Event when its Start Date is within the Days Before key value.

https://github.com/sswinford-dcc/MP-Event-Registration-Summary-Notification

*****************************************************
****************** BEGIN PROCEDURE ******************
*****************************************************/

-- Start with setting our procedure variables
DECLARE
-- These variables are useful for testing
    @TestMode BIT = 0 -- 0 is regular operation, 1 will run the procedure in test mode without sending any email (console output only)
    ,@TestEmail BIT = 0 -- 0 is regular operation, 1 will send all emails to @TestEmailAddress instead of the Event Primary Contact
    ,@TestEmailAddress VARCHAR(100) = 'you@yourdomain.org' -- Email address that you want to receive emails when @TestEmail is set to 1

-- These variables are set from Configuration Setting Keys
    ,@MessageID INT = (SELECT top 1 Value FROM dp_Configuration_Settings CS WHERE ISNUMERIC(Value) = 1 AND CS.Domain_ID = @DomainID AND CS.Application_Code = 'Services' AND Key_Name = 'NotificationEventRegistrationsSummaryMessageID')
    ,@SendDoW INT = ISNULL((SELECT top 1 Value FROM dp_Configuration_Settings CS WHERE ISNUMERIC(Value) = 1 AND CS.Domain_ID = @DomainID AND CS.Application_Code = 'Services' AND Key_Name = 'NotificationEventRegistrationsSummarySendDoW'),2)
    ,@DaysBefore INT = ISNULL((SELECT top 1 Value FROM dp_Configuration_Settings CS WHERE ISNUMERIC(Value) = 1 AND CS.Domain_ID = @DomainID AND CS.Application_Code = 'Services' AND Key_Name = 'NotificationEventRegistrationsSummaryDaysBefore'),3)

-- And these variables are used later in the procedure
    ,@ContactID INT = 0
    ,@EmailTo VARCHAR (500)
    ,@EmailSubject VARCHAR(1000)
    ,@EmailBody VARCHAR(MAX)
    ,@EventList VARCHAR(MAX) = ''
    ,@EmailFrom VARCHAR(500)
    ,@EmailReplyTo VARCHAR(500)
    ,@CopyMessageID INT
    ,@BaseURL NVARCHAR(250) = ISNULL((SELECT Top 1 Value from dp_Configuration_Settings CS WHERE CS.Domain_ID = @DomainID AND CS.Application_Code = 'SSRS' AND CS.Key_Name = 'BASEURL'),'')
    
-- Check that the template Message ID actually exists and our key values are not NULL before running the procedure
IF EXISTS (SELECT 1 FROM dp_Communications Com WHERE Com.Communication_ID = @MessageID AND Com.Domain_ID = @DomainID AND @SendDoW IS NOT NULL AND @DaysBefore IS NOT NULL)
BEGIN

    -- Set some initial variables based on the template
	SET @EmailBody = ISNULL((SELECT Top 1 Body FROM dp_Communications C WHERE C.Communication_ID = @MessageID),'')
	SET @EmailSubject = ISNULL((SELECT Top 1 Subject FROM dp_Communications C WHERE C.Communication_ID = @MessageID),'')
    SET @EmailFrom = ISNULL((SELECT Top 1 '"' + Nickname + ' ' + Last_Name + '" <' + Email_Address + '>' FROM Contacts C LEFT JOIN dp_Communications Com ON Com.From_Contact = C.Contact_ID WHERE C.Contact_ID = Com.From_Contact AND Com.Communication_ID = @MessageID),'')
    SET @EmailReplyTo = ISNULL((SELECT Top 1 '"' + Nickname + ' ' + Last_Name + '" <' + Email_Address + '>' FROM Contacts C LEFT JOIN dp_Communications Com ON Com.Reply_to_Contact = C.Contact_ID  WHERE C.Contact_ID = Com.Reply_to_Contact AND Com.Communication_ID = @MessageID),'')

    -- Create our cursor list (recipient list)
    DECLARE CursorEmailList CURSOR FAST_FORWARD FOR
	    SELECT DISTINCT Contact_ID = C.Contact_ID
	        ,Email_To = ISNULL('"' +  C.Nickname + ' ' + C.Last_Name + '" <' + C.Email_Address + '>','')
	        ,Email_Subject = @EmailSubject
	        ,Email_Body = REPLACE(REPLACE(@EmailBody,'[Nickname]',ISNULL(C.Nickname,C.Display_Name)),'[BaseURL]',@BaseURL)
	    FROM Contacts C
	        LEFT JOIN Events E ON E.Primary_Contact = C.Contact_ID
        WHERE C.Email_Address IS NOT NULL
            AND EXISTS (SELECT *
                            FROM Events E
                            WHERE E.Primary_Contact = C.Contact_ID
                                AND E.Event_Start_Date >= GetDate()
                            -- We're using this next line to determine if it's our Send Day of Week, or if this user has any imminent events coming up
                                AND ((DATEPART(weekday,GetDate()) = @SendDoW) OR (E.Event_Start_Date BETWEEN GetDate() AND GetDate() + @DaysBefore))
                                AND E.Visibility_Level_ID = 4
                                AND E.Online_Registration_Product IS NOT NULL
                        )
	        AND C.Domain_ID = @DomainID

    -- Now lets open the list and create notifications from it
    OPEN CursorEmailList
	FETCH NEXT FROM CursorEmailList INTO @ContactID, @EmailTo, @EmailSubject, @EmailBody
		WHILE @@FETCH_STATUS = 0
			BEGIN
                -- We initially set the @EventList variable with some opening HTML for the email template
                SET @EventList = '<table cellspacing=0 cellpadding=0 border=0 width="100%" style="border-collapse:collapse;"><tr><td align="left" valign="top" width="50%" style="font-weight:bold;border-bottom:1px solid black;padding:5px 2px;">Event</td><td align="left" valign="top" style="font-weight:bold;border-bottom:1px solid black;padding:5px 2px;">Date</td><td align="right" valign="top" style="font-weight:bold;border-bottom:1px solid black;padding:5px 2px;">Registrants</td></tr>'
                -- And then concatenate onto that the details for each individual event. You can modify the HTML to adjust the styling of the table
                SELECT @EventList = COALESCE(@EventList + '<tr style="border-bottom: 1px dotted #CCC;"><td align="left" valign="top" style="padding:5px 2px;">' + ISNULL('<a href="' + @BaseURL + '#/308/' + CONVERT(VARCHAR,E.Event_ID),'') + CASE WHEN E.Event_ID IS NULL THEN '' ELSE '">' END + E.Event_Title + CASE WHEN E.Event_ID IS NULL THEN '' ELSE '</a>' END + '</td><td align="left" valign="top" style="padding:5px 2px;">' + CONVERT(VARCHAR,E.Event_Start_Date) + '</td><td align="right" valign="top" style="padding:5px 2px;">' + CONVERT(VARCHAR,(SELECT COUNT(*) FROM Event_Participants EP WHERE EP.Event_ID = E.Event_ID)) + '</tr>','')
				    FROM Events E
                        LEFT JOIN Contacts C ON E.Primary_Contact = C.Contact_ID
				    WHERE E.Primary_Contact = @ContactID
                        AND E.Event_Start_Date >= GetDate()
						AND E.Event_Start_Date <= GetDate() + 180
                    -- This next line *should* limit those early notification messages to only show the events starting soon
                        AND ((DATEPART(weekday,GetDate()) = @SendDoW) OR (E.Event_Start_Date BETWEEN GetDate() AND GetDate() + @DaysBefore))
						AND E.Visibility_Level_ID = 4
						AND E.Registration_Active = 1
						AND E.Online_Registration_Product IS NOT NULL
					ORDER BY E.Event_Start_Date ASC
                -- Finally, concatenate @EventList with a closing table tag since we're done with the table now
				SET @EventList = @EventList + '</table>'

				-- Check our @TestMode flag, in case we're testing
                IF @TestMode = 0
	                BEGIN
                        
                        -- Replace placeholder in email template with our content
                        SET @EmailBody = ISNULL(REPLACE(@EmailBody,'[Event_List]',@EventList),@EmailBody)

                        -- Create our Communication record
		                INSERT INTO [dbo].[dp_Communications]
				            ([Author_User_ID]
				            ,[Subject]
				            ,[Body]
				            ,[Domain_ID]
				            ,[Start_Date]
				            ,[Expire_Date]
				            ,[Communication_Status_ID]
				            ,[From_Contact]
				            ,[Reply_to_Contact]
				            ,[_Sent_From_Task]
				            ,[Selection_ID]
				            ,[Template]
				            ,[Active]
				            ,[To_Contact]) 
		                SELECT [Author_User_ID]
				            ,@EMailSubject AS [Subject]
        				    ,@EmailBody AS Body
				            ,[Domain_ID]
				            ,[Start_Date] = GETDATE() 
				            ,[Expire_Date]
				            ,[Communication_Status_ID] = 3
				            ,[From_Contact]
				            ,[Reply_to_Contact]
				            ,[_Sent_From_Task] = NULL 
				            ,[Selection_ID] = NULL
				            ,[Template] = 0
				            ,[Active] = 0
				            ,[To_Contact]
		                FROM  dp_Communications Com 
		                WHERE Com.Communication_ID = @MessageID 

                        -- Set our variable to the same ID as the item we just created
                        SET @CopyMessageID = SCOPE_IDENTITY()

                        -- And now create our actual communication message record
                        INSERT INTO [dbo].[dp_Communication_Messages]
				            ([Communication_ID]
				            ,[Action_Status_ID]
				            ,[Action_Status_Time]
				            ,[Action_Text]
				            ,[Contact_ID]
				            ,[From]
				            ,[To]
				            ,[Reply_To]
				            ,[Subject]
				            ,[Body]
				            ,[Domain_ID]
				            ,[Deleted])  
		                SELECT DISTINCT [Communication_ID] = @CopyMessageID 
				            ,[Action_Status_ID] = 2
				            ,[Action_Status_Time] = GETDATE()
				            ,[Action_Text] = NULL
				            ,[Contact_ID] = @ContactID 
				            ,[From] = @EmailFrom
				            ,[To] = CASE WHEN @TestEmail = 0 THEN @EmailTo ELSE @TestEmailAddress END
				            ,[Reply_To] = @EmailReplyTo
				            ,[Subject] = @EmailSubject
				            ,[Body] = @EmailBody 
				            ,[Domain_ID] = @DomainID
				            ,[Deleted] = 0
		            END
				ELSE
                    -- If we're testing, just print out these results in console
					BEGIN
						SELECT @ContactID, @EmailTo, @EmailSubject, @EventList
					END

            -- And now move on to the next recipient in our cursor list
			FETCH NEXT FROM CursorEmailList INTO  @ContactID, @EmailTo, @EmailSubject, @EmailBody

        -- Done fetching
        END

    -- Done with the cursor list, so let's clear it  
	DEALLOCATE CursorEmailList

-- Done with our initial 'if template exists'
END
