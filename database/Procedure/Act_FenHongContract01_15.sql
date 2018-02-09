USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Act_FenHongContract01_15]    Script Date: 2/9/2018 3:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[Act_FenHongContract01_15]
@UcId varchar(200),
@output varchar(200) output
as

declare @ParentId varchar(20),
		@UserId varchar(20) 
select @ParentId=[ParentId],@UserId=[UserId] from [N_UserContract] where Id=@UcId

--判断活动是否已领取
declare @IsGet int
select @IsGet=count(*) from Act_AgentFHRecord where UserId=@UserId and DATEDIFF(day,STime,GETDATE())=0
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

--查询25-09消费量
SELECT @bet=(isnull(sum(Bet),0)-isnull(sum(Cancellation),0)) FROM [N_UserMoneyStatAll] with(nolock)
where (STime>=Convert(varchar(7),getdate(),120)+'-01 00:00:00' and STime<Convert(varchar(7),getdate(),120)+'-16 00:00:00')
and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

--查询10-24亏损量
SELECT @loss=isnull(sum(Bet),0)-(isnull(sum(Win),0)+isnull(sum(Give),0)+isnull(sum(Change),0)+isnull(sum(Cancellation),0)+isnull(sum(Point),0))
FROM [N_UserMoneyStatAll] with(nolock)
where (STime>=Convert(varchar(7),getdate(),120)+'-01 00:00:00' and STime<Convert(varchar(7),getdate(),120)+'-16 00:00:00')
and dbo.f_GetUserCode(UserId) like '%'+dbo.f_User8Code(@UserId)+'%'

if(@loss<0)
begin
set @output='您未亏损！'
return;
end
--判断消费是否具备条件
declare @IsTrue int
select @IsTrue=count(*) from N_UserContractDetail with(nolock) where UcId=@UcId and @bet>=MinMoney*150000 
if(@IsTrue<1)
begin
set @Per=0
end
else
begin
--取出对应的工资百分比
select top 1 @Per=[Money] from N_UserContractDetail with(nolock) where UcId=@UcId and @bet>=MinMoney*150000 order by MinMoney desc
end
--计算得到的金额
set @money=convert(decimal(18,4),@Per)*convert(decimal(18,4),@loss)/100
set @output=@money
declare @sqlstr varchar(200)
--派发工资
if(@money>0)
begin
 INSERT INTO [Act_AgentFHRecord]([UserId],[AgentId],[StartTime],[EndTime],[Bet],[Total],[Per],[InMoney],[STime],[Remark])
      VALUES(@userId,99,Convert(varchar(7),getdate(),120)+'-01 00:00:00',Convert(varchar(7),getdate(),120)+'-16 00:00:00',@bet,@loss,@per,@money,GETDATE(),'契约分红')
 exec Act_UserAgentFHOperTran @ParentId,@userId,'ActFenHong','契约分红',@money,@sqlstr output
end

set @output='领取成功'

return 1;
