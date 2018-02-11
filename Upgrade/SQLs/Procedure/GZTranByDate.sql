USE [Ticket]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if (exists (select 1 from sys.objects where name = N'GZTranByDate'))
    drop proc GZTranByDate
go

/*
	结算指定日期的工资
	@gzdate: 结算日期
*/
CREATE PROCEDURE GZTranByDate
@parentId varchar(20),
@userId varchar(20),
@ActiveType varchar(20),
@ActiveName varchar(20),
@bet decimal(18,4),
@money decimal(18,4),
@gzdate DateTime, --工资结算日期
@result varchar(200) output 
as
BEGIN
	declare @ssId varchar(50),
			@moneyAfter decimal(18,4),
			@userMoney decimal(18,4)
			
	select @userMoney=Money from N_User where Id=@parentId;
	set @moneyAfter=convert(decimal(18,4),@userMoney)-convert(decimal(18,4),@money)

	--if(@moneyAfter>=0)
	--begin
		update [N_User] set Money=convert(decimal(18,4),Money) - convert(decimal(18,4),@money) where Id=@parentId
		select @SsId='A_'+SUBSTRING(replace(newid(), '-', ''),0,19)
		--插入账变记录
		insert into N_UserMoneyLog (SsId,UserId,LotteryId,PlayId,SysId,MoneyChange,MoneyAgo,moneyAfter,STime,IsOk,Code,IsSoft,Remark,STime2,Md5Code) 
		values(@ssId, @parentId, 0, 0, 0, -@money, @UserMoney, @moneyAfter, @gzdate, 1, 100, 2, @ActiveName, GETDATE(), substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',@ssId+''+Convert(varchar(10),'9')+''+Convert(varchar(10),@parentId))),3,32))
		
		if exists (select Id from N_UserMoneyStatAll where UserId=@parentId and datediff(d, STime, @gzdate)=0)
		begin
			Update N_UserMoneyStatAll set Give=Give-@money where  UserId=@parentId and datediff(d, STime, @gzdate)=0
		end
		else
		begin
			Insert into N_UserMoneyStatAll(UserId,Give,STime) values (@parentId, -@money, @gzdate)
		end
	--end

	declare @SsId2 varchar(50),@MoneyAfter2 decimal(18,4),@UserMoney2 decimal(18,4)
	select @UserMoney2=Money from N_User where Id=@UserId;
	set @MoneyAfter2=convert(decimal(18,4),@UserMoney2)+convert(decimal(18,4),@money)
	--if(@MoneyAfter2>=0)
	--begin
		update [N_User] set Money=convert(decimal(18,4),Money)+convert(decimal(18,4),@money) where Id=@UserId
		select @SsId2='A_'+SUBSTRING(replace(newid(), '-', ''),0,19)
		--插入账变记录
		insert into N_UserMoneyLog (SsId,UserId,LotteryId,PlayId,SysId,MoneyChange,MoneyAgo,MoneyAfter,STime,IsOk,Code,IsSoft,Remark,STime2,Md5Code) 
		values(@SsId2,@UserId,0,0,0,@money,@UserMoney2,@MoneyAfter2,@gzdate,1,100,2,@ActiveName,GETDATE(),substring(sys.fn_sqlvarbasetostr(HashBytes('MD5',@SsId2+''+Convert(varchar(10),'9')+''+Convert(varchar(10),@UserId))),3,32))

		if exists (select Id from N_UserMoneyStatAll where UserId=@UserId and datediff(d,STime,@gzdate)=0)
		begin
			Update N_UserMoneyStatAll set Give=Give+@money where  UserId=@UserId and datediff(d,STime,@gzdate)=0
		end
		else
		begin
			Insert into N_UserMoneyStatAll(UserId,Give,STime) values (@UserId,@money,@gzdate)
		end

		--插入活动记录
		INSERT INTO [Act_ActiveRecord](SsId,[UserId],[ActiveType],[ActiveName],[Bet],[InMoney],[STime],[CheckIp],[CheckMachine],[FromUserId],[Remark])
		VALUES(@SsId2, @userId, @ActiveType, @ActiveName, @bet, @money, @gzdate, N'系统自动派发', N'系统自动派发', @parentId, @ActiveName)
	--end


	set @result='领取成功'+Convert(varchar(100),@money)


	--set @result='领取成功'
	return '1'
END