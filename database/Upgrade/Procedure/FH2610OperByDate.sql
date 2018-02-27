USE [Ticket]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if (exists (select 1 from sys.objects where name = N'FH2610OperByDate'))
    drop proc FH2610OperByDate
go

/*
	结算上月26号到当月10号的分红
	@fhdate: 结算日期
*/

CREATE PROCEDURE FH2610OperByDate
@contractId varchar(200), --契约Id
@fhdate DateTime, --分红结算日期
@result varchar(200) output
as
BEGIN
	DECLARE @startTime DATETIME, @endTime DATETIME, @days INT
	SET @startTime = CAST((Convert(varchar(7),DateAdd(mm,-1,@fhdate),120)+'-26 00:00:00') AS DATETIME)
	SET @endTime = CAST((Convert(varchar(7),@fhdate,120)+'-10 23:59:59') AS DATETIME)
	SET @days = DateDiff(d, @startTime, @endTime) + 1

	declare @parentId varchar(20),
			@userId varchar(20) 
	select @parentId=[ParentId], @userId=[UserId] from [N_UserContract] where Id = @contractId
	
	--判断活动是否已领取
	declare @isGet int
	select @IsGet=count(*) from Act_AgentFHRecord where UserId=@UserId and DATEDIFF(day,STime,@fhdate)=0
	
	if(@IsGet>0)
	begin
		set @result='今天已领取！'
		return;
	end

	declare @money decimal(18,4),
			@bet decimal(18,4),
			@loss decimal(18,4),
			@Per decimal(18,4),
			@GroupName varchar(200)

	--查询上月26号到当月10号消费量
	SELECT @bet=(isnull(sum(Bet),0)-isnull(sum(Cancellation),0)) FROM [N_UserMoneyStatAll] with(nolock)
	where (STime>=Convert(varchar(7),DateAdd(mm,-1,@fhdate),120)+'-26 00:00:00' and STime<Convert(varchar(7),@fhdate,120)+'-11 00:00:00')
	and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

	--查询上月26号到当月10号亏损量
	SELECT @loss=isnull(sum(Bet),0)-(isnull(sum(Win),0)+isnull(sum(Give),0)+isnull(sum(Change),0)+isnull(sum(Cancellation),0)+isnull(sum(Point),0))
	FROM [N_UserMoneyStatAll] with(nolock)
	where (STime>=Convert(varchar(7),DateAdd(mm,-1,@fhdate),120)+'-26 00:00:00' and STime<Convert(varchar(7),@fhdate,120)+'-11 00:00:00')
	and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

	if(@loss<0)
	begin
		set @result='您未亏损！'

		--添加派发日志记录
		DELETE FROM Log_ContractOper WHERE UserId=@userId AND DATEDIFF(d, @fhdate, OperTime) =0	AND Type =1
		INSERT INTO Log_ContractOper(UserId, ParentId, ContractId, Type, Money, Bet, Loss, Remark, OperTime, STime, Allowed) 
				VALUES(@userId, @ParentId, @contractId, 1, 0, @bet, @loss, @result, @fhdate, GETDATE(), 0);

		return;
	end
	--判断消费是否具备条件
	declare @IsTrue int
	select @IsTrue=count(*) from N_UserContractDetail with(nolock) where UcId=@contractId and [Money] > 0 and @bet>=MinMoney*@days*10000 
	if(@IsTrue<1)
	begin
		set @Per=0
	end
	else
	begin
		--取出对应的工资百分比
		select top 1 @Per=[Money] from N_UserContractDetail with(nolock) where UcId=@contractId and [Money] > 0 
		and @bet>=MinMoney*@days*10000 order by MinMoney desc
	end
	
	--计算得到的金额
	set @money=convert(decimal(18,4),@Per)*convert(decimal(18,4),@loss)/100
	set @result=@money
	
	
	--判断父级是否发放分红，并且父级账号不是平台管理账户，如果未发放，则不允许发放分红
	declare @isParGet int
	declare @state BIT = 0
	select @isParGet=count(*) from Act_AgentFHRecord where UserId=@parentId and DATEDIFF(day, STime, @fhdate)=0
	if(@isParGet<=0 AND EXISTS(SELECT 1 FROM N_User WHERE Id=@parentId AND ISNULL(parentId, 0) > 0))
	begin
		set @result='父级会员未领取分红'
		SELECT @state = CASE WHEN @money >0 THEN 1 ELSE 0 END
	end
	else
	begin
		--派发工资
		if(@money>0)
		begin
			INSERT INTO [Act_AgentFHRecord]([UserId],[AgentId],[StartTime],[EndTime],[Bet],[Total],[Per],[InMoney],[STime],[Remark])
				VALUES(@userId,99,@startTime,@endTime,@bet,@loss,@per,@money,@fhdate,'系统契约分红')
		
			exec FHTranByDate @parentId, @userId,'ActFenHong',N'契约分红',@money,@fhdate,@result output

			set @result = N'领取成功'
		end
		else
			set @result = N'未满足分红契约亏损额度'
	end	
	
	--添加派发日志记录
	DELETE FROM Log_ContractOper WHERE UserId=@userId AND DATEDIFF(d, @fhdate, OperTime) =0	AND Type = 1
	INSERT INTO Log_ContractOper(UserId, ParentId, ContractId, Type, Money, Bet, Loss, Per, Remark, OperTime, STime, Allowed) 
			VALUES(@userId, @ParentId, @contractId, 1, @money, @bet, @loss, @per, @result, @fhdate, GETDATE(), @state);

	return 1;
END