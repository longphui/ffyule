USE [Ticket]
GO
/****** Object:  UserDefinedFunction [dbo].[f_GetHistoryCode]    Script Date: 2018/2/11 22:09:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [dbo].[f_GetHistoryCode](@state varchar(10))
returns varchar(50)
as 
  begin
  Declare @stateName varchar(50)
  if @state='0'
          begin 
          set @stateName='未知代码'
          end
  else if  @state='1' 
          begin
          set @stateName='账户充值'
          end
  else if  @state='2' 
          begin
          set @stateName='账户提款'
          end
  else if  @state='3' 
          begin
          set @stateName='投注扣款'
          end
  else if  @state='4' 
          begin
          set @stateName='游戏返点'
          end
  else if  @state='5' 
          begin
          set @stateName='奖金派送'
          end
  else if  @state='6' 
          begin
          set @stateName='撤单返款'
          end
  else if  @state='7' 
          begin
          set @stateName='转出资金'
          end
  else if  @state='8' 
          begin
          set @stateName='转入资金'
          end
  else if  @state='9' 
          begin
          set @stateName='活动礼金'
          end  
  else if  @state='10' 
          begin
          set @stateName='其他'
          end  
  else if  @state='11' 
  begin
		set @stateName='积分兑换'
  end
  else if  @state='12' 
  begin
	set @stateName='分红'
  end
  else if  @state='13' 
  begin
	set @stateName='日结工资'
  end

  return @stateName
  end
