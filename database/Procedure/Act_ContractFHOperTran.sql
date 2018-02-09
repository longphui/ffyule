USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Act_ContractFHOperTran]    Script Date: 2/9/2018 3:43:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[Act_ContractFHOperTran]
@parentId varchar(20),
@userId varchar(20),
@ActiveType varchar(20),
@ActiveName varchar(20),
@money decimal(18,4),
@output varchar(200) output 
as



if not exists (select Id from Act_AgentFHRecord where userid=1405 and datediff(d,STime,getdate())=0)
begin
declare @SsId varchar(50),@MoneyAfter decimal(18,4),@UserMoney decimal(18,4)
select @UserMoney=Money from N_User where Id=@parentId;
set @MoneyAfter=convert(decimal(18,4),@UserMoney)-convert(decimal(18,4),@money)

if(@MoneyAfter>=0)
begin
	update [N_User] set Money=convert(decimal(18,4),Money)+convert(decimal(18,4),@money) where Id=@parentId
	select @SsId='A_'+SUBSTRING(replace(newid(), '-', ''),0,19)
	--插入账变记录
	insert into N_UserMoneyLog (SsId,UserId,LotteryId,PlayId,SysId,MoneyChange,MoneyAgo,MoneyAfter,STime,IsOk,Code,IsSoft,Remark,STime2,Md5Code) 
	values(@SsId,@parentId,0,0,0,-@money,@UserMoney,@MoneyAfter,GETDATE(),1,99,2,@ActiveName,GETDATE(),substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',@SsId+''+Convert(varchar(10),'9')+''+Convert(varchar(10),@parentId))),3,32))
	
	if exists (select Id from N_UserMoneyStatAll where UserId=@parentId and datediff(d,STime,GETDATE())=0)
	begin
			Update N_UserMoneyStatAll set AgentFH=AgentFH-@money where  UserId=@parentId and datediff(d,STime,GETDATE())=0
	end
	else
	begin
			Insert into N_UserMoneyStatAll(UserId,AgentFH,STime) values (@parentId,-@money,GETDATE())
	end

end

declare @SsId2 varchar(50),@MoneyAfter2 decimal(18,4),@UserMoney2 decimal(18,4)
select @UserMoney2=Money from N_User where Id=@UserId;
set @MoneyAfter2=convert(decimal(18,4),@UserMoney2)+convert(decimal(18,4),@money)
if(@MoneyAfter>=0)
begin
	update [N_User] set Money=convert(decimal(18,4),Money)+convert(decimal(18,4),@money) where Id=@UserId
	select @SsId2='A_'+SUBSTRING(replace(newid(), '-', ''),0,19)
	--插入账变记录
	insert into N_UserMoneyLog (SsId,UserId,LotteryId,PlayId,SysId,MoneyChange,MoneyAgo,MoneyAfter,STime,IsOk,Code,IsSoft,Remark,STime2,Md5Code) 
	values(@SsId2,@UserId,0,0,0,@money,@UserMoney2,@MoneyAfter2,GETDATE(),1,99,2,@ActiveName,GETDATE(),substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',@SsId2+''+Convert(varchar(10),'9')+''+Convert(varchar(10),@UserId))),3,32))

	if exists (select Id from N_UserMoneyStatAll where UserId=@UserId and datediff(d,STime,GETDATE())=0)
	begin
			Update N_UserMoneyStatAll set AgentFH=AgentFH+@money where  UserId=@UserId and datediff(d,STime,GETDATE())=0
	end
	else
	begin
			Insert into N_UserMoneyStatAll(UserId,AgentFH,STime) values (@UserId,@money,GETDATE())
	end
end


	set @output='领取成功'+Convert(varchar(100),@money)

end
	--set @output='领取成功'
return '1'
