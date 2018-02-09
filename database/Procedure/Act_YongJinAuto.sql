USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Act_YongJinAuto]    Script Date: 2/9/2018 3:46:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[Act_YongJinAuto]
@userId varchar(200),
@output varchar(200) output
as

--判断活动是否开启
declare @IsOpen int
select @IsOpen=count(*) from Act_ActiveSet where Code='ActDayYongJin' and IsUse=0  and (getdate() >= StartTime or getdate() <= EndTime)
if(@IsOpen=0)
begin
set @output='活动已关闭！'
return;
end

--判断活动是否已领取
declare @IsGet int
select @IsGet=count(*) from Act_ActiveRecord where UserId=@userId and ActiveType='ActYongJin' and DATEDIFF(day,STime,GETDATE())=0
if(@IsGet>0)
begin
set @output='今天已领取！'
return;
end

--得到亏损
declare @loss decimal(18,4)
SELECT @loss=isnull(isnull(sum(Bet),0)-(isnull(sum(Win),0)+isnull(sum(Point),0)+isnull(sum(Give),0)+isnull(sum(Cancellation),0)),0) FROM [N_UserMoneyStatAll] a 
where UserId=@userId  and DateDiff(dd,STime,getdate())=1 
if(@loss<=0)
begin
set @output='今天未亏损！'
return;
end

declare @money decimal(18,4),
@count int,
@group2 decimal(18,4),
@group3 decimal(18,4)

SELECT @count=count(*) FROM Act_SetYJDetail2 where IsUsed=0 and MinMoney<=@loss
if(@count>0)
begin
SELECT top 1 @group2=group2,@group3=group3 FROM Act_DayYJSet where IsUsed=0 and MinMoney<=@loss order by Id desc
end
else
begin
set @group2=0 
set @group3=0
end


declare @ParentId int
select @ParentId=ParentId from N_User where Id=@userid
if(@ParentId<>0)
begin

--派发佣金
declare @sqlstr varchar(200)
if(@group2>0)
begin
 exec Act_UserOperTran @ParentId,'ActYongJin','亏损佣金',@loss,@group2,@userId,@sqlstr output
end


declare @ParentId2 int
select @ParentId2=ParentId from N_User where Id=@ParentId
if(@ParentId<>0)
begin
--派发佣金
declare @sqlstr2 varchar(200)
if(@group3>0)
begin
 exec Act_UserOperTran @ParentId2,'ActYongJin','亏损佣金',@loss,@group3,@userId,@sqlstr2 output
end
end

end

set @output='领取成功'

return 1;
