USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Act_UserOperTran]    Script Date: 2/9/2018 3:46:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[Act_UserOperTran]
@userId varchar(20),
@ActiveType varchar(20),
@ActiveName varchar(20),
@bet decimal(18,4),
@money decimal(18,4),
@FromUserId varchar(20),
@output varchar(200) output 
as

declare @SsId varchar(50)
select @SsId='A_'+SUBSTRING(replace(newid(), '-', ''),0,19)
if not exists (select Id from [Act_ActiveRecord] where userid =@userId and FromUserId=@FromUserId and ActiveType=@ActiveType and datediff(d,STime,getdate())=0)
begin

--插入活动记录
INSERT INTO [Act_ActiveRecord](SsId,[UserId],[ActiveType],[ActiveName],[Bet],[InMoney],[STime],[CheckIp],[CheckMachine],[FromUserId],[Remark])
VALUES(@SsId,@userId,@ActiveType,@ActiveName,@bet,@money,GETDATE(),'系统自动派发','系统自动派发',@FromUserId,@ActiveName)

--插入账变记录
insert into N_UserMoneyLog (SsId,UserId,LotteryId,PlayId,SysId,MoneyChange,STime,IsOk,Code,IsSoft,Remark,STime2,Md5Code) 
values(@SsId,@userId,0,0,0,@money,GETDATE(),1,9,2,@ActiveName,GETDATE(),substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',@SsId+''+Convert(varchar(10),'9')+''+Convert(varchar(10),@userId))),3,32))

end

return '1'
