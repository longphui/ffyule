USE [Ticket]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if (exists (select 1 from sys.objects where name = N'FH0115OperByDate'))
    drop proc FH0115OperByDate
go

/*
	结算指定月份1号到15号的工资
	@fhdate: 结算日期
*/
CREATE PROCEDURE FH0115OperByDate
@contractId varchar(200), --契约Id
@fhdate DateTime, --工资结算日期
@result varchar(200) output
as
BEGIN
	declare @parentId varchar(20),
			@userId varchar(20) 
	select @parentId=[ParentId], @userId=[UserId] from [N_UserContract] where Id = @contractId

	--判断活动是否已领取
	declare @isGet int
	select @isGet=count(*) from Act_AgentFHRecord where UserId=@UserId and DATEDIFF(day, STime, @fhdate)=0
	
	if(@isGet>0)
	begin
		set @result='今天已领取！'
		return;
	end

	declare @money decimal(18,4),
			@bet decimal(18,4),
			@loss decimal(18,4),
			@Per decimal(18,4),
			@GroupName varchar(200)

	--查询01-15消费量
	SELECT @bet=(isnull(sum(Bet),0)-isnull(sum(Cancellation),0)) FROM [N_UserMoneyStatAll] with(nolock)
	where (STime>=Convert(varchar(7),@fhdate,120)+'-01 00:00:00' and STime<Convert(varchar(7),@fhdate,120)+'-16 00:00:00')
	and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

	--查询01-15亏损量
	SELECT @loss=isnull(sum(Bet),0)-(isnull(sum(Win),0)+isnull(sum(Give),0)+isnull(sum(Change),0)+isnull(sum(Cancellation),0)+isnull(sum(Point),0))
	FROM [N_UserMoneyStatAll] with(nolock)
	where (STime>=Convert(varchar(7),@fhdate,120)+'-01 00:00:00' and STime<Convert(varchar(7),@fhdate,120)+'-16 00:00:00')
	and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

	if(@loss<0)
	begin
		set @result='您未亏损！'
		return;
	end
	
	--判断消费是否具备条件
	declare @IsTrue int
	select @IsTrue=count(*) from N_UserContractDetail with(nolock) where UcId=@contractId and @bet>=MinMoney*150000 
	
	if(@IsTrue<1)
	begin
		set @Per=0
	end
	else
	begin
		--取出对应的工资百分比
		select top 1 @Per=[Money] from N_UserContractDetail with(nolock) where UcId=@contractId and @bet>=MinMoney*150000 order by MinMoney desc
	end
	
	--计算得到的金额
	set @money=convert(decimal(18,4),@Per)*convert(decimal(18,4),@loss)/100
	set @result=@money
	
	--派发工资
	if(@money>0)
	begin
		INSERT INTO [Act_AgentFHRecord]([UserId],[AgentId],[StartTime],[EndTime],[Bet],[Total],[Per],[InMoney],[STime],[Remark])
			VALUES(@userId,99,Convert(varchar(7),@fhdate,120)+'-01 00:00:00',Convert(varchar(7),@fhdate,120)+'-16 00:00:00',@bet,@loss,@per,@money,@fhdate,N'契约分红')
		exec FHTranByDate @ParentId,@userId,'ActFenHong','契约分红',@money,@fhdate,@result output
	end

	set @result='领取成功'

	return 1;
END
