USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Global_UserOperTran]    Script Date: 2/9/2018 3:46:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[Global_UserOperTran]
@LogSsId varchar(50),
@LogUserId varchar(20),
@LogUserMoney decimal(18,4),
@LogStatMoney decimal(18,4),
@LogStatType varchar(20),
@LogLotteryId int,
@LogPlayId int,
@LogSysId int,
@LogCode int, 
@LogIsSoft int,
@LogReMark varchar(200),
@LogMessageTitle varchar(50),
@LogMessageContent varchar(200),
@STime2 datetime,
@output varchar(200) output 
as

declare @rowsNum int;
select @rowsNum=count(*) from N_UserMoneyLog where Md5Code=substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',@LogSsId+''+Convert(varchar(10),@LogCode)+''+Convert(varchar(10),@LogUserId))),3,32)
if(@rowsNum>0 and @LogCode<>2)
BEGIN
	set @output='0'
END
ELSE
BEGIN
	if(@STime2='')
	begin
		Insert into N_UserMoneyLog(SsId,UserId,LotteryId,PlayId,SysId,MoneyChange,Code,IsSoft,remark,STime2,Md5Code)
		values(@LogSsId,@LogUserId,@LogLotteryId,@LogPlayId,@LogSysId,@LogUserMoney,@LogCode,@LogIsSoft,@LogReMark,Getdate()
		,substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',Convert(varchar(10),@LogCode)+''+@LogSsId+''+Convert(varchar(10),@LogUserId))),3,32))
	end
	else
	begin
		Insert into N_UserMoneyLog(SsId,UserId,LotteryId,PlayId,SysId,MoneyChange,Code,IsSoft,remark,STime2,Md5Code)
		values(@LogSsId,@LogUserId,@LogLotteryId,@LogPlayId,@LogSysId,@LogUserMoney,@LogCode,@LogIsSoft,@LogReMark,@STime2
		,substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',Convert(varchar(10),@LogCode)+''+@LogSsId+''+Convert(varchar(10),@LogUserId))),3,32))
	end
	set @output='1'
end
return '1'
