#Graph: IR
library(ggplot2)
df <- data.frame(timeatrisk=c(3, 6, 12, 24, 36, 48, 60),
                 target=c(0.14, 0.26, 0.51, 0.67, 0.77, 0.82, 0.82),
                 comparator=c(0.23, 0.34, 0.55, 0.64, 0.70, 0.72, 0.73))
head(df)
ggplot() +
  geom_line(data=df, aes(x=timeatrisk, y=target, group = 1, color = 'essure'))+
  geom_line(data=df, aes(x=timeatrisk, y=comparator, group = 1, color = 'IUD'))+
  geom_point(data=df, aes(x=timeatrisk, y=target, group = 1))+
  geom_point(data=df, aes(x=timeatrisk, y=comparator, group = 1))+
  labs(title="ESSURE vs Intrauterine devices on need for surgery", 
       x="Time at risk, months", y="Incidence rates")+
  theme(plot.title=element_text(size=13), axis.title.x=element_text(size=10), 
        axis.title.y=element_text(size=10), axis.text.x=element_text(size=10))+
  scale_x_discrete(name ="Time at risk, months", 
                   limits=c(3, 6, 12, 24, 36, 48, 60))+
  scale_color_discrete(name = "")

#Graph: RR
library(ggplot2)
df <- data.frame(timeatrisk=c(3, 6, 12, 24, 36, 48, 60),
                 RR=c(0.62, 0.76, 0.93, 1.05, 1.11, 1.13, 1.12),
                 CIlow=c(0.40, 0.54, 0.73, 0.84, 0.90, 0.92, 0.91),
                 CIup=c(0.96, 1.06, 1.19, 1.31, 1.37, 1.39, 1.38))
head(df)
ggplot()+
  geom_line(data=df, aes(x=timeatrisk, y=RR, group = 1))+
  geom_point(data=df, aes(x=timeatrisk, y=RR, group = 1))+
  geom_errorbar(data=df, aes(x=timeatrisk, ymin=CIlow, ymax=CIup), colour="black")+
  labs(title="ESSURE vs Laparoscopic sterilization on pregnancy", 
       x="Time at risk, months", y="Relative risk")+
  theme(plot.title=element_text(size=13), axis.title.x=element_text(size=10), 
        axis.title.y=element_text(size=10), axis.text.x=element_text(size=10))+
  scale_x_discrete(name ="Time at risk, months", 
                   limits=c(3, 6, 12, 24, 36, 48, 60))+
  geom_hline(yintercept=1, linetype="dashed", color = "blue")
