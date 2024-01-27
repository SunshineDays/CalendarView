一款轻量级的Swift日历弹窗，以月为单位展示，点击收起并展示当前日期

简单地调用示例

        /// 0:为当前月，1为后一个月，-1为前一个月，以此类推
        calendarView.setMonth(offset: 0)
        /// 会根据当前状态展示
        calendarView.show()
        /// 展示上一个月
        calendarView.last()
        /// 展示下一个月
        calendarView.next()
