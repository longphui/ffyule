USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Act_FenHong01_15]    Script Date: 2/9/2018 3:44:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	
ALTER proc [dbo].[Act_FenHong01_15]
@GroupId varchar(200),
@userId varchar(200),
@output varchar(200) output
as
BEGIN		
	/*** 计算逻辑
		会员盈利达到一定额度，
		允许会员得到亏损金额的契约分红
	***/
	
	/*** 20180210
		不区分用户组UserGroup
		只执行Task_AutoActFenHong01_15_Group3, Task_AutoActFenHong16_31_Group3
		清除Task_AutoActFenHong01_15_Group4, Task_AutoActFenHong16_31_Group4
	***/
	
	--判断活动是否开启
	declare @IsOpen int
	select @IsOpen=count(*) from Act_ActiveSet where Code='ActDay15Fenhong' and IsUse=0 and (getdate() >= StartTime or getdate() <= EndTime)
	if(@IsOpen=0)
	begin
		set @output='活动已关闭！'
		return;
	end

	--判断活动是否已领取
	declare @IsGet int
	select @IsGet=count(*) from Act_AgentFHRecord where UserId=@userId and DATEDIFF(day,STime,GETDATE())=0

	if(@IsGet>0)
	begin
		set @output='今天已领取！'
		return;
	end

	declare @money decimal(18,4),
	@bet decimal(18,4),
	@loss decimal(18,4),
	@Per decimal(18,4),
	@GroupName varchar(200)

	--查询1-15号的消费量
	SELECT @bet=(isnull(sum(Bet),0)-isnull(sum(Cancellation),0)) FROM [N_UserMoneyStatAll] with(nolock)
	where (STime>=Convert(varchar(7),getdate(),120)+'-01 00:00:00' and STime<Convert(varchar(7),getdate(),120)+'-16 00:00:00')
	and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

	--查询1-15号的亏损量
	SELECT @loss=isnull(sum(Bet),0)-(isnull(sum(Win),0)+isnull(sum(Give),0)+isnull(sum(Change),0)+isnull(sum(Cancellation),0)+isnull(sum(Point),0))
	FROM [N_UserMoneyStatAll] with(nolock)
	where (STime>=Convert(varchar(7),getdate(),120)+'-01 00:00:00' and STime<Convert(varchar(7),getdate(),120)+'-16 00:00:00')
	and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

	if(@loss < 0)
	begin
		set @output='您未亏损！'
		return;
	end

	--判断消费是否具备条件
	-- 15天 * 10000单位
	declare @IsTrue int
	select @IsTrue=count(1) from N_UserContract UC with(nolock) INNER JOIN N_UserContractDetail CD with(nolock) ON UC.Id = CD.UcId 
		where UC.[Type] = 1 AND UC.UserId=@UserId and ISNULL(UC.IsUsed, 0) =1 and @bet >= CD.MinMoney * (15 * 10000)
	
	if(@IsTrue < 1)
	begin
		set @Per=0
	end
	else
	begin
		--用户组
		select @GroupName = name where N_UserGroup WHERE Id = @GroupId
		
		--取出对应的工资百分比
		select top 1 @Per=CD.Money
			from N_UserContract UC with(nolock) INNER JOIN N_UserContractDetail CD with(nolock) ON UC.Id = CD.UcId  
			where UC.[Type] = 1 AND UC.UserId=@UserId and ISNULL(UC.IsUsed, 0) =1 and @bet >= CD.MinMoney * (15 * 10000)
			order by CD.MinMoney desc
	end

	--根据亏损金额，计算得到的分红金额
	set @money=convert(decimal(18, 4), @Per) * convert(decimal(18, 4), @loss) / 100
	set @output=@money

	declare @sqlstr varchar(200)

	--派发分红
	if(@money > 0)
	begin
	 INSERT INTO [Act_AgentFHRecord]([UserId],[AgentId],[StartTime],[EndTime],[Bet],[Total],[Per],[InMoney],[STime],[Remark])
		  VALUES(@userId,@GroupId,Convert(varchar(7),getdate(),120)+'-01 00:00:00',Convert(varchar(7),getdate(),120)+'-16 00:00:00',@bet,@loss,@per,@money,GETDATE(),@GroupName)
	 exec Act_UserAgentFHOperTran @userId,'ActFenHong',@GroupName,@money,@userId,@sqlstr output
	end

	set @output='领取成功'

	return 1;
END
