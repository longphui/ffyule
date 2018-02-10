USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Act_Gongzi_Group]    Script Date: 2/9/2018 3:44:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[Act_Gongzi_Group]
@GroupId varchar(10),
@userId varchar(10),
@ActiveType varchar(20),
@ActiveName varchar(20),
@output varchar(200) output
as
BEGIN
		
	/*** 计算逻辑
		会员销量达到一定额度，
		允许会员得到相应比例的日结工资
	***/
	

	/*** 20180210
		不区分用户组UserGroup
		只执行Task_AutoActGongZi_Group2
		清除Task_AutoActGongZi_Group3, Task_AutoActGongZi_Group4
	***/
	

	--判断活动是否开启
	declare @IsOpen int
	select @IsOpen=count(*) from Act_ActiveSet where Code='ActDayGongZi' and IsUse=0 and (getdate() >= StartTime or getdate() <= EndTime)
	
	if(@IsOpen=0)
	begin
		set @output='活动已关闭！'
		return;
	end

	--判断活动是否已领取
	declare @IsGet int
	select @IsGet=count(*) from Act_ActiveRecord where UserId=@userId and ActiveType=@ActiveType and DATEDIFF(day,STime,GETDATE())=0
	
	if(@IsGet>0)
	begin
		set @output='今天已领取！'
		return;
	end

	declare @bet decimal(18,4),
	@hyNum int,
	@money decimal(18,4)

	--销量
	SELECT @bet=isnull(cast(round((isnull(Sum(bet),0)-isnull(Sum(Cancellation),0)),4) as numeric(20,4)),0) FROM [N_UserMoneyStatAll] a 
	where dbo.f_GetUserCode(UserId) like '%,'+@userId+',%'  and DateDiff(dd,STime,getdate())=0

	--select @hyNum=count(*) from (select Userid FROM [N_UserMoneyStatAll] 
	--where dbo.f_GetUserCode(UserId) like '%,'+@userId+',%' and (Bet-Cancellation)>1000 and DateDiff(dd,STime,getdate())=1 group by Userid) A

	declare @IsTrue int
	select @IsTrue=count(1) from N_UserContract UC with(nolock) INNER JOIN N_UserContractDetail CD with(nolock) ON UC.Id = CD.UcId 
		where UC.[Type] = 2 AND UC.UserId=@UserId and ISNULL(UC.IsUsed, 0) =1 and @bet >= CD.MinMoney * 10000 --and MinUsers<=@hyNum 
		
	if(@IsTrue > 0)
	begin
		--取出对应的工资百分比
		select top 1 @money=cast(round([CD.Money] * @bet *0.01, 4) as numeric(10,4))
			from N_UserContract UC with(nolock) INNER JOIN N_UserContractDetail CD with(nolock) ON UC.Id = CD.UcId  
			where UC.[Type] = 2 AND UC.UserId=@UserId and ISNULL(UC.IsUsed, 0) =1 and @bet >= CD.MinMoney * 10000 --and MinUsers<=@hyNum
			order by CD.MinMoney desc
	end
	else
	begin
		set @money=0
	end

	declare @sqlstr varchar(200)
	--派发工资
	if(@money>0)
	begin
	 exec Act_UserOperTran @userId,@ActiveType,@ActiveName,@bet,@money,@userId,@sqlstr output
	end
	set @output='领取成功'

	return 1;
END
