USE [Ticket]
GO
/****** Object:  Trigger [dbo].[TR_UserMoneyLog_Update]    Script Date: 2018/2/11 22:06:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER trigger [dbo].[TR_UserMoneyLog_Update] 
on [dbo].[N_UserMoneyLog] 
for insert --插入触发
as

declare 
@LogSsId varchar(32),
@LogCode varchar(10),
@UserId int,
@MoneyChange decimal(18,4),
@UserMoney decimal(18,4),
@STime2 datetime,
@Id int

select @Id=Id,@LogSsId=SsId,@LogCode=Code,@UserId=UserId,@MoneyChange=MoneyChange,@STime2=STime2 from inserted;

if(@LogCode=99)
BEGIN
update [N_UserMoneyLog] set Code=12 where Id=@Id
end
else if(@LogCode=100)
begin
update [N_UserMoneyLog] set Code=13 where Id=@Id
end
else
begin
select @UserMoney=Money from N_User where Id=@UserId;
declare @MoneyAfter decimal(18,4)
set @MoneyAfter=convert(decimal(18,4),@MoneyChange)+convert(decimal(18,4),@UserMoney)
if(@MoneyAfter>=0)
BEGIN
	update [N_UserMoneyLog] set MoneyAgo=@UserMoney,MoneyAfter=@MoneyAfter where Id=@Id
	update [N_User] set Money=convert(decimal(18,4),Money)+convert(decimal(18,4),@MoneyChange) where Id=@UserId
	declare @STatAllId varchar(10)
	if exists (select Id from N_UserMoneyStatAll where UserId=@UserId and datediff(d,STime,@STime2)=0)
	begin
		select @STatAllId=Id from N_UserMoneyStatAll where UserId=@UserId and datediff(d,STime,@STime2)=0
		if(@LogCode=1)
			Update N_UserMoneyStatAll set [Charge]=[Charge]+@MoneyChange where Id=@STatAllId
		if(@LogCode=2)
			Update N_UserMoneyStatAll set [GetCash]=[GetCash]-@MoneyChange where Id=@STatAllId
		--if(@LogCode=3)
		--	Update N_UserMoneyStatAll set [Bet]=[Bet]-@MoneyChange where Id=@STatAllId
		if(@LogCode=4)
			Update N_UserMoneyStatAll set [Point]=[Point]+@MoneyChange where Id=@STatAllId
		if(@LogCode=5)
			Update N_UserMoneyStatAll set [Win]=[Win]+@MoneyChange where Id=@STatAllId
		if(@LogCode=6)
			Update N_UserMoneyStatAll set Bet=Bet+@MoneyChange,[Cancellation]=[Cancellation]+@MoneyChange where Id=@STatAllId
		if(@LogCode=9)
			Update N_UserMoneyStatAll set [Give]=[Give]+@MoneyChange where Id=@STatAllId
		if(@LogCode=10)
			Update N_UserMoneyStatAll set [Other]=[Other]+@MoneyChange where Id=@STatAllId
		if(@LogCode=11)
			Update N_UserMoneyStatAll set [Change]=[Change]+@MoneyChange where Id=@STatAllId
		if(@LogCode=12)
			Update N_UserMoneyStatAll set [AgentFH]=[AgentFH]+@MoneyChange where Id=@STatAllId
	end
	else
	begin
		if(@LogCode=1)
			Insert into N_UserMoneyStatAll(UserId,[Charge],STime) values (@UserId,@MoneyChange,@STime2)
		if(@LogCode=2)
			Insert into N_UserMoneyStatAll(UserId,[GetCash],STime) values (@UserId,-@MoneyChange,@STime2)
		if(@LogCode=3)
			Insert into N_UserMoneyStatAll(UserId,[Bet],STime) values (@UserId,0,@STime2)
		if(@LogCode=4)
			Insert into N_UserMoneyStatAll(UserId,[Point],STime) values (@UserId,@MoneyChange,@STime2)
		if(@LogCode=5)
			Insert into N_UserMoneyStatAll(UserId,[Win],STime) values (@UserId,@MoneyChange,@STime2)
		if(@LogCode=6)
			Insert into N_UserMoneyStatAll(UserId,Bet,[Cancellation],STime) values (@UserId,@MoneyChange,@MoneyChange,@STime2)
		if(@LogCode=9)
			Insert into N_UserMoneyStatAll(UserId,[Give],STime) values (@UserId,@MoneyChange,@STime2)
		if(@LogCode=10)
			Insert into N_UserMoneyStatAll(UserId,[Other],STime) values (@UserId,@MoneyChange,@STime2)
		if(@LogCode=11)
			Insert into N_UserMoneyStatAll(UserId,[Change],STime) values (@UserId,@MoneyChange,@STime2)
		if(@LogCode=12)
			Insert into N_UserMoneyStatAll(UserId,[AgentFH],STime) values (@UserId,@MoneyChange,@STime2)
	end
END
end




